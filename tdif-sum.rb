db = Hash.new(0)
n = 0
for line in ARGF
  a = line.chomp.split(/\t/)
  case a.first
  when /^#/ then
  when /^\d/ then
    dt = a[0].to_i
    dt = (dt / 10) * 10
    x = a[1].to_i
    n += x
    db[dt] += x
  end
end

puts "#n\t#{n}"
db.keys.sort.each {|dt|
  puts [dt, db[dt]].join("\t")
}
