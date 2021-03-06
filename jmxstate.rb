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
    '気象特別警報・警報・注意報' => {
      :type => '気象警報・注意報（市町村等）',
      :abr => 'warn' },
    '地方海上警報（Ｈ２８）' => {
      :type => '地方海上警報',
      :abr => 'marw' },
    '土砂災害警戒情報' => {
      :type => '土砂災害警戒情報',
      :abr => 'dosha' },
    '指定河川洪水予報' => {
      :type => '指定河川洪水予報（予報区域）',
      :abr => 'kasen' }
  }

  def titleCheck title
    return if TYPETAB[title]
    throw(:skipMsg, "unknown title #{title}") if @opts[:fast]
  end

  def typeCheck type
    puts "#typeCheck(#{type.inspect})" if $VERBOSE
    if type.nil? then
      @itemdata = nil
    else
      title = @meta['title']
      if TYPETAB[title] and TYPETAB[title][:type] == type
        @itemdata = {}
      else
        puts "#typeCheck unknown '#{title}' => '#{type}'" if $VERBOSE
      end
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
    abr = TYPETAB[@meta['title']][:abr]
    @itemdata[:areas].each{|area|
      @itemdata[:kinds].each{|kind|
        obj = [abr, area[:code], kind[:code]].join('.')
        @callback.call('obj' => obj, 'state' => kind[:code],
          'aname' => area[:name],
          'kname' => kind[:name],
          'utime' => @meta['utime'],
          'expire' => @meta['expire'])
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
    when '/Report/Head/Headline/Information/Item/Kind' 
      @itemdata[:kindbuf] = {} if @itemdata
    when '/Report/Head/Headline/Information/Item/Areas/Area'
      @itemdata[:areabuf] = {} if @itemdata
    end
  end

  def tag_end(name)
    case @xpath
    when '/Report/Head/Headline/Information' then typeCheck(nil)
    when '/Report/Head/Headline/Information/Item' then itemEnd
    when '/Report/Head/Headline/Information/Item/Kind' 
      @itemdata[:kinds].push @itemdata[:kindbuf] if @itemdata
    when '/Report/Head/Headline/Information/Item/Areas/Area'
      @itemdata[:areas].push @itemdata[:areabuf] if @itemdata
    when '/Report/Head' then
      title = @meta['title']
      throw(:skipMsg, "unknown title #{title}") unless TYPETAB[@meta['title']]
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
    when '/Report/Control/DateTime' then @meta['utime'] = str
    when '/Report/Head/ValidDateTime' then @meta['expire'] = str
    # data
    when '/Report/Head/Headline/Information/Item/Kind/Code' then
      @itemdata[:kindbuf][:code] = str if @itemdata and @itemdata[:kindbuf]
    when '/Report/Head/Headline/Information/Item/Kind/Name' then
      @itemdata[:kindbuf][:name] = str if @itemdata and @itemdata[:kindbuf]
    when '/Report/Head/Headline/Information/Item/Areas/Area/Code' then
      @itemdata[:areabuf][:code] = str if @itemdata and @itemdata[:areabuf]
    when '/Report/Head/Headline/Information/Item/Areas/Area/Name' then
      @itemdata[:areabuf][:name] = str if @itemdata and @itemdata[:areabuf]
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
    @in_state = @out_state = @out_fnam = nil
    @files = []
  end

  def cancelWarning objpat, row
    re = /^#{Regexp.quote(objpat)}/
    @out_state.keys.each {|objid|
      next unless re === objid
      xrow = row.dup
      xrow['obj'] = objid
      xrow['kname'] = @out_state['kname']
      @out_state[objid] = xrow
    }
  end

  def msgscan name, mtime, body, opts
    listener = JMXParser.new(opts) {|row|
      objid = row['obj']
      case objid
      when /^(dosha\.\d+)\.1$/ then cancelWarning($1, row)
      when /^(\w+\.\d+)\.0+$/ then cancelWarning($1, row)
      else
        @out_state[objid] = row
      end
    }
    r = catch(:skipMsg) {
      REXML::Parsers::StreamParser.new(body, listener).parse
      nil
    }
    if r then
      puts "#skip #{r}" if $VERBOSE
    end
  end

  def tgzfile fnam
    rawio = File.open(fnam, 'rb')
    rawio.set_encoding('BINARY')
    require 'zlib'
    io = Zlib::GzipReader.new(rawio)
    Archive::Tar::Minitar::Reader.open(io) { |tar|
      tar.each_entry {|ent|
        msgscan(ent.name, Time.at(ent.mtime), ent.read, @opts)
      }
    }
  ensure
    io.close
    rawio.close
  end

  def tarfile fnam
    io = File.open(fnam, 'rb')
    io.set_encoding('BINARY')
    Archive::Tar::Minitar::Reader.open(io) { |tar|
      tar.each_entry {|ent|
        msgscan(ent.name, Time.at(ent.mtime), ent.read, @opts)
      }
    }
  ensure
    io.close
  end

  def xmlfile fnam
    mtime = File.stat(fnam).mtime
    File.open(fnam, 'rb') {|io|
      io.set_encoding('BINARY')
      msgscan(fnam, mtime, io.read, @opts)
    }
  end

  def ltsv_load fnam
    result = {}
    File.open(fnam, 'rt') {|fp|
      fp.each_line {|line|
        row = Hash[* line.chomp.split(/\t/).map {|c| c.split(/:/, 2)}]
        objid = row['obj']
        @in_state[objid] = row
      }
    }
    result
  end

  def filearg arg
    if @in_state.nil?
      @in_state = ltsv_load(arg)
    elsif @out_state.nil?
      @out_fnam = arg
      @out_state = @in_state.dup
    else
      case arg
      when /\.xml$/ then xmlfile(arg)
      when /\.t(ar\.)?gz$/ then tgzfile(arg)
      else tarfile(arg)
      end
    end
  end

  def ltsv_save db, fnam
    File.open(fnam, 'wt') {|fp|
      db.each {|obj, row|
        fp.puts row.map{|k,v| [k, v].join(':')}.join("\t")
      }
    }
  end

  def run argv
    hyphen_is_flag = true
    argv.each{|arg|
      if hyphen_is_flag then
        case arg
        when '--' then hyphen_is_flag = false
        when '--fast' then @opts[:fast] = true
        when /^-/ then $stderr.puts "unknown option #{arg}"
        else filearg(arg)
        end
      else
        filearg(arg)
      end
    }
    ltsv_save(@out_state, @out_fnam)
  ensure
    syslog
  end

  def syslog
    @logger.info('elapsed %g', Time.now - @onset)
  end

end

App.new.run(ARGV)
