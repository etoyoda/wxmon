require 'time'

stab = Hash.new(0)

for line in ARGF
  row = {}
  line.chomp.split(/\t/).each {|cell| k, v = cell.split(/:/, 2); row[k] = v }

  next unless row['lmtime']
  lmt = Time.parse(row['lmtime']).utc
  s = lmt.sec
  stab[s] += 1

end

raise "empty input" if stab.empty?

smax = stab.keys.max
0.upto(smax){|s|
  puts [s, stab[s].to_i].join("\t")
}
