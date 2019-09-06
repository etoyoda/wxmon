require 'time'
require 'gdbm'

pushdb = ARGV.shift
raise Errno::ENOENT, pushdb unless FileTest.exist?(pushdb)

udb = Hash.new
for line in ARGF
  row = {}
  line.chomp.split(/\t/).each {|cell| k, v = cell.split(/:/, 2); row[k] = v }
  u = Time.parse(row['utime']).utc
  msgid = row['msgid'].to_s
  udb[msgid] = u
end

n = 0
nfail = 0
dttab = Hash.new(0)

GDBM::open(pushdb, GDBM::READER) {|db|
  postid = db['postid'].to_i
  1.upto(postid) {|id|
    mtime = Time.parse(db["upd:#{id}"]).utc
    ents = db["bdy:#{id}"].to_s.split(/<entry>/)
    ents.shift
    ents.each{|ent|
      next unless /<id>(.*?)<\/id>/ === ent
      msgid = $1
      utime = udb[msgid]
      n += 1
      if utime then
        dt = (mtime - utime).floor
        dttab[dt] += 1
        if dt > 300 then
          STDERR.puts [msgid, utime, mtime, dt].inspect
        end
      else
        nfail += 1
      end
    }
  }
}

puts "#fail\t#{nfail}\t#{n}\t#{"%4.2f" % (nfail.to_f/n*100)} %"
0.upto(dttab.keys.max) {|dt|
  puts "#{dt}\t#{dttab[dt]}"
}
