require 'time'
require 'gdbm'

pushdb = ARGV.shift
raise Errno::ENOENT, pushdb unless FileTest.exist?(pushdb)

udb = Hash.new
for line in ARGF
  row = {}
  line.chomp.split(/\t/).each {|cell| k, v = cell.split(/:/, 2); row[k] = v }
  utstr = row['lmtime']
  next unless utstr
  u = Time.parse(utstr).utc
  msgid = row['msgid'].to_s
  udb[msgid] = u
end

n = 0
nfail = 0
npushmiss = 0
dttab = Hash.new(0)
pstab = Hash.new

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
      pstab[msgid] = mtime
      n += 1
      if utime then
        dt = (mtime - utime).floor
        dttab[dt] += 1
        if dt > 300 then
          STDERR.puts [msgid, utime, mtime, dt].inspect if $VERBOSE
        end
      else
        mtimes = mtime.strftime('%Y-%m-%dT%H:%M:%SZ')
        tee = sprintf("#pullmiss\tmtime:%s\t%s\n", mtimes, msgid)
        puts tee
        STDERR.puts tee
        nfail += 1
      end
    }
  }
  for msgid in udb.keys
    next if pstab.include?(msgid)
    utimes = udb[msgid].strftime('%Y-%m-%dTH%:%M:%SZ')
    tee = sprintf("#pushmiss\tutime:%s\t%s\n", utimes, msgid)
    puts tee
    STDERR.puts tee
    npushmiss += 1
  end
}

printf("#stat\tn=%u\tpull=%u\t%4.2f\tpush=%u\t%4.2f\n", n, nfail, nfail*100.0/n,
  npushmiss, npushmiss*100.0/n)
0.upto(dttab.keys.max) {|dt|
  puts "#{dt}\t#{dttab[dt]}"
}
