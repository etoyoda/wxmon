#!/usr/bin/ruby

require 'gdbm'
require 'time'

fnam = ARGV.shift
lhs = ARGV.shift || 'JDDS'
rhs = ARGV.shift || 'JMAXML'
pdb = {}

GDBM.open(fnam, 0666, GDBM::READER) {|db|
  maxidx = db['postid'].to_i
  0.upto(maxidx) {|i|
    tpn = db["tpn:#{i}"]
    upd = db["upd:#{i}"]
    next unless upd
    mtime = Time.parse(upd)
    ents = db["bdy:#{i}"].to_s.split(/<entry>/)
    ents.shift
    ents.each{|ent|
      next unless /<id>(.*?)<\/id>/ === ent
      msgid = $1
      pdb[msgid] = {} unless pdb.include?(msgid)
      pdb[msgid][tpn] = mtime
    }
  }
}
for msgid, h in pdb
  dt = if h[lhs] && h[rhs] then h[lhs] - h[rhs] else nil end
  puts [dt, h[lhs], h[rhs], msgid].inspect
end
