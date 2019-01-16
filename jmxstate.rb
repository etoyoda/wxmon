#!/usr/bin/ruby
# coding: utf-8

require 'rubygems'
require 'archive/tar/minitar'
require 'syslog'

class JMXParser
  require 'rexml/parsers/baseparser'
  require 'rexml/parsers/streamparser'
  require 'rexml/streamlistener'
  include REXML::StreamListener

  def initialize opts = {}
    # essentials
    @path = ['']
    @xpath = nil
    @callback = proc
    @meta = {}
    # used in parsing //Item[@type = right one for title]
    @itemdata = nil
    @opts = opts
  end

  def endOfDocument
  end

  TYPETAB = {
    '気象特別警報・警報・注意報' => '気象警報・注意報（市町村等）',
    '地方海上警報（Ｈ２８）' => '地方海上警報',
    '土砂災害警戒情報' => '土砂災害警戒情報'
  }

  def titleCheck title
    return if TYPETAB[title]
    throw(:unknownTitle, title) if @opts[:fast]
  end

  def typeCheck type
    puts "#typeCheck(#{type.inspect})" if $VERBOSE
    if type.nil? then
      @itemdata = nil
    elsif TYPETAB[@meta['title']] == type
      @itemdata = {}
    else
      puts "#typeCheck unknown '#{@meta['title']}' => '#{type}'"
    end
  end

  def itemStart
    return unless @itemdata
    puts "#itemStart" if $VERBOSE
    @itemdata[:kinds] = []
    @itemdata[:areas] = []
  end

  def itemEnd
    return unless @itemdata
    puts "#itemEnd" if $VERBOSE
    @itemdata[:areas].each{|areaCode|
      @itemdata[:kinds].each{|kindCode|
        @callback.call(:area => areaCode, :kind => kindCode, :title => @meta['title'],
          'utime' => @meta['utime'], 'expire' => @meta['expire'])
      }
    }
    @itemdata = {}
  end

  def tag_start(name, attrs)
    @path.push(name)
    @xpath = @path.join('/')
    case @xpath
    when '/Report/Head/Headline/Information' then typeCheck(attrs['type'])
    when '/Report/Head/Headline/Information/Item' then itemStart
    end
  end

  def tag_end(name)
    case @xpath
    when '/Report/Head/Headline/Information' then typeCheck(nil)
    when '/Report/Head/Headline/Information/Item' then itemEnd
    when '/Report/Head' then
      throw(:unknownTitle, @meta['title']) unless TYPETAB[@meta['title']]
    end
    @path.pop
    @xpath = @path.join('/')
    endOfDocument if @xpath.empty?
  end

  def text(str)
    case @xpath
    # fields to identify message
    when '/Report/Control/Title' then titleCheck(@meta['title'] = str)
    when '/Report/Control/Status' then @meta['status'] = str
    #when '/Report/Control/EditorialOffice' then @meta['edof'] = str
    #when '/Report/Head/EventID' then @meta['evid'] = str
    when '/Report/Control/DateTime' then @meta['utime'] = str
    when '/Report/Head/ValidDateTime' then @meta['expire'] = str
    # data
    when '/Report/Head/Headline/Information/Item/Kind/Code' then
      @itemdata[:kinds].push str if @itemdata
    when '/Report/Head/Headline/Information/Item/Areas/Area/Code' then
      @itemdata[:areas].push str if @itemdata
    else
      return
    end
    # normalize-space
    str.gsub!(/[\r\n\v\f\t ]+/, ' ')
    str.gsub!(/^ /, '')
    str.gsub!(/ $/, '')
  end

end

class App

  def initialize
    @onset = Time.now
    @logger = Syslog.open('jmxstate', Syslog::LOG_PID, Syslog::LOG_NEWS)
    @opts = { :fast => false }
  end

  def msgscan name, mtime, body, opts
    listener = JMXParser.new(opts) {|tup|
      p tup
    }
    r = catch(:unknownTitle) {
      REXML::Parsers::StreamParser.new(body, listener).parse
      nil
    }
    if r then
      puts "#unknown title #{r}" if $VERBOSE
    end
  end

  def tarfile fnam
    case fnam
    when '--fast' then
      @opts[:fast] = true
      return
    when /\.xml$/ then
      File.open(fnam, 'rb') {|io|
        io.set_encoding('BINARY')
        msgscan(fnam, File.stat(fnam).mtime, io.read, @opts)
      }
      return
    end
    begin
      rawio = io = File.open(fnam, 'rb')
      io.set_encoding('BINARY')
      if /\.gz$/ === fnam then
        require 'zlib'
        io = Zlib::GzipReader.new(rawio)
      end
      Archive::Tar::Minitar::Reader.open(io) { |tar|
        tar.each_entry {|ent|
          msgscan(ent.name, Time.at(ent.mtime), ent.read, @opts)
        }
      }
    ensure
      io.close
      rawio.close unless io == rawio
    end
  end

  def syslog
    @logger.info('elapsed %g', Time.now - @onset)
  end

  def run argv
    argv.each{|arg| tarfile(arg); GC.start }
    syslog
  end

end

App.new.run(ARGV)
