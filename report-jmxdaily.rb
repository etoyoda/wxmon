#!/usr/bin/ruby
# coding: utf-8

require 'time'
require 'rubygems'

class JMXParser
  require 'rexml/parsers/baseparser'
  require 'rexml/parsers/streamparser'
  require 'rexml/streamlistener'
  include REXML::StreamListener

  def initialize
    @path = ['']
    @xpath = nil
    @callback = proc
    @flag = nil
    @msgs = {}
    @row = nil
  end

  def endOfDocument
    @callback.call(@msgs.keys)
  end

  def tag_start(name, attrs)
    @path.push(name.sub(/^\w+:/, ''))
    @xpath = @path.join('/')
    case @xpath
    when '/Report/Body/MeteorologicalInfos/TimeSeriesInfo/Item/Kind/Property'
      @flag = true
      @row = {}
    end
  end

  def tag_end(name)
    case @xpath
    when '/Report/Body/MeteorologicalInfos/TimeSeriesInfo/Item/Kind/Property'
      if @row[:flag]
        msg = (@row[:text] || "#{@row[:type]}: #{@row[:flag]}. ")
        @msgs[msg] = true
      end
      @flag = false
    end
    @path.pop
    @xpath = @path.join('/')
    endOfDocument if @xpath == ''
  end

  def text(str)
    return unless @flag
    case @xpath
    when /\/Type$/ then @row[:type] = str
    when /\/Text$/ then @row[:text] = str
    when /\/PossibilityRankOfWarning$/ then
      case str
      when /中/ then
        unless @row[:flag] then @row[:flag] = $& end
      when /高/ then
        @row[:flag] = $&
      end
    end
  end

end

class App

  @@hacktitles = %w[
警報級の可能性（明日まで）
警報級の可能性（明後日以降）
  ]

  @@titles = %w[

津波警報・注意報・予報a
気象特別警報報知
津波情報a
全般気象情報
地方気象情報
府県気象情報
指定河川洪水予報
土砂災害警戒情報
警報級の可能性（明日まで）
警報級の可能性（明後日以降）
全般台風情報（定型）
記録的短時間大雨情報
竜巻注意情報（目撃情報付き）
特殊気象報
季節観測
噴火警報・予報
降灰予報（詳細）
生物季節観測
震度速報
異常天候早期警戒情報
地方高温注意情報
府県潮位情報
スモッグ気象情報
地方天候情報
地震の活動状況等に関する情報
地方１か月予報
地方３か月予報

  ]

  def initialize argv
    @argv = []
    @cutoff = nil
    argv.each{|arg|
      case arg
      when /^--cutoff=/ then
        @cutoff = Time.parse($').utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      when /^--/ then
        raise "unknown option #{arg}"
      else @argv.push arg
      end
    }
    @db = {}
    @fixdb = {}
  end

  @@ioopts = {
    :invalid => :replace,
    :undef => :replace
  }

  def check row
    mtime, title, edof = row['mtime'], row['title'], row['edof']
    return if @cutoff and mtime < @cutoff
    return unless @@titles.include?(title)
    @db[title] = Hash.new unless @db[title]
    @db[title][edof] = [] unless @db[title][edof]
    rec = Hash.new
    rec[:rtime] = Time.parse(row['rtime']).localtime.strftime('%dT%H:%M')
    hdline = (row['hdline'] || '')
    hdline = nil if hdline.empty? and @@hacktitles.include?(title)
    rec[:hdline] = hdline
    ymd = Time.parse(row['mtime']).utc.strftime('%Y-%m-%d')
    uuid = row['msgid']
    @fixdb[uuid] = rec unless rec[:hdline]
    rec[:url] = "https://tako.toyoda-eizi.net/syndl/entry/#{ymd}/jmx/#{uuid}"
    @db[title][edof].unshift rec
  end

  def compile
    @argv.each{|fnam|
      File.open(fnam, 'rt') {|fp|
        fp.set_encoding('utf-8', @@ioopts)
        fp.each_line { |line|
          row = Hash[*(line.chomp.split(/\t/).map{|cell| cell.split(/:/,2)}.flatten)]
          check(row)
        }
      }
    }
  end

  def realmsg name, body
    listener = JMXParser.new {|msgs|
      @fixdb[name][:hdline] = msgs.join(' ') unless msgs.empty?
    }
    REXML::Parsers::StreamParser.new(body, listener).parse
  end

  def tarfile fnam
    require 'archive/tar/minitar'
    rawio = io = nil
    begin
      io = File.open(fnam, 'rb')
      io.set_encoding('BINARY')
    rescue Errno::ENOENT
      require 'zlib'
      rawio = File.open(fnam + ".gz", 'rb')
      rawio.set_encoding('BINARY')
      io = Zlib::GzipReader.new(rawio)
    end
    Archive::Tar::Minitar::Reader.open(io) { |tar|
      tar.each_entry {|ent|
        next unless @fixdb[ent.name]
        realmsg(ent.name, ent.read)
      }
    }
  ensure
    io.close if io
    rawio.close if rawio
  end

  def fix
    @argv.each{|fnam|
      tarfile fnam.sub(/(\.ltsv)?$/, '.tar')
    }
    ## filtering
    title_to_kill = []
    @@titles.each{|title|
      next unless @db[title]
      next unless @@hacktitles.include?(title)
      edof_to_kill = []
      @db[title].keys.each{|edof|
        mlist2 = []
        @db[title][edof].each{|rec|
        $stderr.puts "## #{title} #{edof} #{rec[:hdline]}"
          next unless rec[:hdline]
          next if rec[:hdline].empty?
          mlist2.push rec
        }
        @db[title][edof] = mlist2
        edof_to_kill.push edof if mlist2.empty?
      }
      edof_to_kill.each{|edof|
        @db[title].delete(edof)
      }
      title_to_kill.push title if @db[title].empty?
    }
    title_to_kill.each{|title|
      @db.delete(title)
    }
  end

  def subjline
    buf = ["~s 電文モニタ"]
    @@titles.each {|title|
      next unless @db[title]
      n = 0
      @db[title].each{|edof,mlist| n += mlist.size}
      buf.push "#{n}x#{title[0,4]}"
    }
    buf.join(', ')
  end

  def report
    @@titles.each {|title|
      writeln "= #{title}"
      unless @db[title]
        writeln "ありません。"
        next
      end
      writeln ''
      @db[title].each{|edof,mlist|
        bedof = edof.sub(/気象庁本庁/, '本庁').sub(/(管区気象台|地方気象台|測候所)$/, '')
        mlist.each {|msg|
          sgn = "[#{bedof} #{msg[:rtime]}] "
          sgn += msg[:hdline] if msg[:hdline]
          writeln sgn
          writeln "<#{msg[:url]}>"
        }
      }
      writeln ''
    }
    writeln '(END)'
    writeln subjline
  end

  def writeln str
    $stdout.puts str rescue Errno::EPIPE
  end

  def run
    compile
    fix
    report
  end

end

App.new(ARGV).run
