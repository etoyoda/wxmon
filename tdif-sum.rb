db = Hash.new(0)
nf = n = 0
for line in ARGF
  a = line.chomp.split(/\t/)
  case a.first
  when /^#fail/ then
    nf += a[1].to_i
    n += a[2].to_i
  when /^\d/ then
    dt = a[0].to_i
    dt = (dt / 10) * 10
    db[dt] += a[1].to_i
  end
end

puts ['#fail', nf, n, "%4.2f" % (100.0 * nf / n)].join("\t")
db.keys.sort.each {|dt|
  puts [dt, db[dt]].join("\t")
}
