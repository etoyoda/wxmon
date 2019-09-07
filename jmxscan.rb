#!/usr/bin/ruby

require 'rubygems'
require 'archive/tar/minitar'
require 'syslog'

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
    @onset = Time.now
    @logger = Syslog.open('jmxscan', Syslog::LOG_PID, Syslog::LOG_NEWS)
    @kill = Hash.new
  end

  def killfile fnam
    File.open(fnam, 'r:utf-8'){|fp|
      fp.each_line {|line|
        next unless /urn:uuid:[-a-f0-9]+/ === line
        @kill[$&] = true
      }
    }
  end

  def msgscan name, mtime, body
    if body.nil?
      @logger.err("nil body msgid:#{name}")
      return
    end
    if body.empty?
      @logger.err("empty body msgid:#{name}")
      return
    end
    if /\0\0\0\0$/ === body
      @logger.err("nul at end of msgid:#{name}")
      return
    end
    listener = JMXParser.new {|tup|
      ary = ["msgid:#{name}", "mtime:#{mtime.utc.strftime('%Y-%m-%dT%H:%M:%SZ')}"]
      tup.each {|k,v| ary.push "#{k}:#{v}" }
      puts ary.join("\t") rescue Errno::EPIPE
    }
    begin
      REXML::Parsers::StreamParser.new(body, listener).parse
    rescue StandardError => e
      msg = e.message.split(/\n/).first
      STDERR.puts "#{e.class.to_s}: #{name} #{msg}"
      if $DEBUG
        fn = "dbg#{name}.xml"
        File.open(fn, 'wb'){|fp| fp.write body }
      end
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
        if @kill[ent.name] then
          #STDERR.puts "#kill #{ent.name}"
          next
        end
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
    argv.each{|arg|
        case arg
        when /^--kill=/ then killfile($')
        else tarfile(arg); GC.start
        end
      }
    syslog
  end

end

App.new.run(ARGV)
