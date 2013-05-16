require 'find'

if ARGV.size != 2
  puts "usage: ruby tool.rb <mimetype> <folder with fits reports>"
  exit
end

mimetype=ARGV[0]
folder=ARGV[1]
conflict_table={}

Find.find(folder) do |file|
  if FileTest.file?(file)
    #    puts "file found: #{file}"
    found_mimetype = false
    File.open(file,"r").each do |line|
      if (line.match(/#{mimetype}/))
        #        puts "found mimetype"
        found_mimetype = true
      end
      #      puts "line: #{line}"
      if line.match(/<([a-zA-Z]*).*status=\"CONFLICT\"/)
        conflict = $1
        if found_mimetype
          #          puts "conflict found: #{conflict}"
          counter = conflict_table[conflict].to_i+1
          conflict_table.store(conflict, counter)
        end
      end
    end
  end
end

conflict_table = conflict_table.sort_by { |key, value| value }.reverse

sum = 0

conflict_table.each do |key,value|
  puts "#{key}: #{value}"
  sum = sum + value
end

puts "sum: #{sum}"