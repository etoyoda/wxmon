#!/usr/bin/ruby

require 'rubygems'
require 'archive/tar/minitar'

class JMXParser
  require 'rexml/parsers/baseparser'
  require 'rexml/parsers/streamparser'
  require 'rexml/streamlistener'
  include REXML::StreamListener

  def initialize
    @tup = {}
    @path = ['']
    @callback = proc
    @xpath = nil
    @data = {}
  end

  def fixHdline
    hdline = @tup['hdline'].to_s
    return unless hdline.empty?
    comment = @data['comment']
    if comment and not comment.empty?
      @tup['hdline'] = comment[0,140]
      return
    end
    if @data['Station/Name'] and @data['Kind/Name'] then
      @tup['hdline'] = @data.values_at("Kind/Name", "Station/Name").join("@")
      return
    end
  end

  def endOfDocument
    fixHdline
    @callback.call(@tup)
  end

  def tag_start(name, attrs)
    @path.push(name)
    @xpath = @path.join('/')
  end

  def tag_end(name)
    @path.pop
    @xpath = @path.join('/')
    endOfDocument if @xpath == ''
  end

  def text(str)
    case @xpath
    # 11 fields on 2012 version of pshbjmx DB. Top four comprises unique key.
    when '/Report/Control/Title' then @tup['title'] = str
    when '/Report/Control/Status' then @tup['status'] = str
    when '/Report/Control/EditorialOffice' then @tup['edof'] = str
    when '/Report/Head/EventID' then @tup['evid'] = str
    when '/Report/Control/DateTime' then @tup['utime'] = str
    when '/Report/Control/PublishingOffice' then @tup['pbof'] = str
    when '/Report/Head/ValidDateTime' then @tup['expire'] = str
    when '/Report/Head/ReportDateTime' then @tup['rtime'] = str
    when '/Report/Head/InfoKind' then @tup['ikind'] = str
    when '/Report/Head/Headline/Text' then @tup['hdline'] = str
    when '/Report/Head/InfoType' then @tup['itype'] = str
    #
    when '/Report/Body/Comment/Text' then @data['comment'] = str
    when %r{^/Report/Body/M\w+/MeteorologicalInfo/Item/((?:Kind|Station)/\w+)$} then
      @data[$1] = str
    else
      return
    end
    str.gsub!(/[\r\n\v\f\t ]+/, ' ')
    str.gsub!(/^ /, '')
    str.gsub!(/ $/, '')
  end

end

class App

  def initialize
  end

  def msgscan name, body
    listener = JMXParser.new {|tup|
      ary = [['msgid:', name].join]
      tup.each {|k,v| ary.push "#{k}:#{v}" }
      puts ary.join("\t") rescue Errno::EPIPE
    }
    REXML::Parsers::StreamParser.new(body, listener).parse
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
        msgscan(ent.name, ent.read)
      }
    }
  ensure
    io.close
    rawio.close unless io == rawio
  end

  def run argv
    argv.each{|arg| tarfile(arg); GC.start }
  end

end

App.new.run(ARGV)
