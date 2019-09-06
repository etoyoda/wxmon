require 'time'

dttab = Hash.new(0)

for line in ARGF
  row = {}
  line.chomp.split(/\t/).each {|cell| k, v = cell.split(/:/, 2); row[k] = v }
  u = Time.parse(row['utime']).utc
  m = Time.parse(row['mtime']).utc
  dt = ((m - u) / 10).floor
  next if m.hour.zero? and m.min < 10 and dt > 60
  dttab[dt] += 1
end

dtmax = dttab.keys.max
0.upto(dtmax){|dt|
  puts [dt * 10, dttab[dt].to_i].join("\t")
}
