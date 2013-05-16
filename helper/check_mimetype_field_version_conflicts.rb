require 'find'

if ARGV.size != 3
  puts "usage: ruby tool.rb <mimetype> <field> <folder with fits reports>"
  exit
end

mimetype=ARGV[0]
field=ARGV[1]
folder=ARGV[2]
conflict_table={}
  
example = ""

Find.find(folder) do |file|
  if FileTest.file?(file)
    #    puts "file found: #{file}"
    found_mimetype = false
    found_version = false
    version = ""
    File.open(file,"r").each do |line|
      if (line.match(/#{mimetype}/))
#        puts "found mimetype"
        found_mimetype = true
      end
      if found_mimetype
        if line.match(/<version.*>(.*)<\/version>/)
          version = $1
          found_version = true
#          puts "version found: #{version}"
        end
      end
      if found_mimetype && found_version
        if line.match(/<#{field}.*status=\"CONFLICT\"/)
#          puts "found conflicted field: #{field}"
          counter = conflict_table[version].to_i+1
          conflict_table.store(version, counter)
          example = file
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
puts "example: #{example}"