require 'time'

dttab = Hash.new(0)
ittab = Hash.new(0)

for line in ARGF
  row = {}
  line.chomp.split(/\t/).each {|cell| k, v = cell.split(/:/, 2); row[k] = v }
  m = Time.parse(row['mtime']).utc

  next unless row['lmtime']
  lmt = Time.parse(row['lmtime']).utc
  dt = ((m - lmt) / 10).floor
  dttab[dt] += 1

  next unless row['utime']
  u = Time.parse(row['utime']).utc
  it = ((lmt - u) / 10).floor
  ittab[it] += 1

end

raise "empty input" if dttab.empty?

dtmax = [dttab.keys.max, ittab.keys.max].max
0.upto(dtmax){|dt|
  puts [dt * 10, dttab[dt].to_i, ittab[dt].to_i].join("\t")
}
