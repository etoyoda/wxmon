require 'time'

since = Time.parse(ARGV.shift or '1970-01-01T00:00:00Z')
before = Time.parse(ARGV.shift or '2199-12-31T23:59:59Z')

for line in ARGF
  h = Hash[*line.chomp.split(/\t/).map{|c|c.split(/:/,2)}.flatten]
  begin
    ut = Time.parse(h['utime'])
  rescue
    p h
  end
  puts line if ut >= since and ut < before
end
