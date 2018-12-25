#!/usr/bin/ruby

require 'time'

class App

  @@titles = %w[

津波警報・注意報・予報a
気象特別警報報知
津波情報a
全般気象情報
地方気象情報
府県気象情報
指定河川洪水予報
土砂災害警戒情報
//警報級の可能性（明日まで）
//警報級の可能性（明後日以降）
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
    @argv = argv
    @db = {}
  end

  @@ioopts = {
    :invalid => :replace,
    :undef => :replace
  }

  def check row
    title, edof = row['title'], row['edof']
    return unless @@titles.include?(title)
    @db[title] = Hash.new unless @db[title]
    @db[title][edof] = [] unless @db[title][edof]
    rec = Hash.new
    rec[:rtime] = Time.parse(row['rtime']).localtime.strftime('%H:%M')
    rec[:hdline] = row['hdline']
    ymd = Time.parse(row['mtime']).utc.strftime('%Y-%m-%d')
    rec[:url] = "https://tako.toyoda-eizi.net/syndl/entry/#{ymd}/jmx/#{row['msgid']}"
    @db[title][edof].push rec
  end

  def run
    @argv.each{|fnam|
      File.open(fnam, 'rt') {|fp|
        fp.set_encoding('utf-8', @@ioopts)
        fp.each_line { |line|
          row = Hash[*(line.chomp.split(/\t/).map{|cell| cell.split(/:/,2)}.flatten)]
          check(row)
        }
      }
    }
    puts @db.inspect
  end

end

App.new(ARGV).run
