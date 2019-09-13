require 'time'

since = Time.parse(ARGV.shift || '1970-01-01T00:00:00Z')
before = Time.parse(ARGV.shift || '2199-12-31T23:59:59Z')
STDERR.puts [since, before].inspect

for line in ARGF
  h = Hash[*line.chomp.split(/\t/).map{|c|c.split(/:/,2)}.flatten]
  begin
    ut = Time.parse(h['utime'])
  rescue
    p h
  end
  puts line if ut >= since and ut < before
end
