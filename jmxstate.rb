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

  def initialize
    # essentials
    @path = ['']
    @xpath = nil
    @callback = proc
    @result = { 'table' => [] }
    # used in parsing //Item[@type = right one for title]
    @itemdata = nil
  end

  def endOfDocument
    @callback.call(@result)
  end

  TYPETAB = {
    "気象特別警報・警報・注意報" => "気象警報・注意報（市町村等）"
  }

  def titleCheck title
    return if TYPETAB[title]
    throw(:unknownTitle, title)
  end

  def typeCheck type
    puts "#typeCheck(#{type.inspect})" if $VERBOSE
    if type.nil? then
      @itemdata = nil
    elsif TYPETAB[@result['title']] == type
      @itemdata = {}
    else
      puts "#typeCheck unkn '#{@result['title']}' => '#{type}'" if $VERBOSE
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
        @result['table'].push [areaCode, kindCode]
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
    end
    @path.pop
    @xpath = @path.join('/')
    endOfDocument if @xpath.empty?
  end

  def text(str)
    case @xpath
    # fields to identify message
    when '/Report/Control/Title' then titleCheck(@result['title'] = str)
    when '/Report/Control/Status' then @result['status'] = str
    when '/Report/Control/EditorialOffice' then @result['edof'] = str
    when '/Report/Head/EventID' then @result['evid'] = str
    when '/Report/Control/DateTime' then @result['utime'] = str
    when '/Report/Head/ValidDateTime' then @result['expire'] = str
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
  end

  def msgscan name, mtime, body
    listener = JMXParser.new {|tup|
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
    rawio = io = File.open(fnam, 'rb')
    io.set_encoding('BINARY')
    if /\.gz$/ === fnam then
      require 'zlib'
      io = Zlib::GzipReader.new(rawio)
    end
    Archive::Tar::Minitar::Reader.open(io) { |tar|
      tar.each_entry {|ent|
        msgscan(ent.name, Time.at(ent.mtime), ent.read)
      }
    }
  ensure
    io.close
    rawio.close unless io == rawio
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
