#!/usr/bin/ruby
for arg in ARGV
  File.open(arg, 'r'){|fp|
    fp.rewind
    totals = Hash.new(0)
    fp.each_line{|line|
      next if /^#/ === line
      a = line.chomp.split(/\t/)
      1.upto(a.size - 1) {|j|
        totals[j] += a[j].to_i
      }
    }
    fp.rewind
    accu = Hash.new(0)
    fp.each_line{|line|
      next if /^#/ === line
      a = line.chomp.split(/\t/)
      b = [a[0]]
      1.upto(a.size - 1) {|j|
        accu[j] += a[j].to_i
        b.push format('%6.2f', 100.0 * accu[j] / totals[j])
      }
      puts b.join("\t")
    }
  }
end
