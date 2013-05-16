require 'find'

if ARGV.size != 1
  puts "usage: ruby tool.rb <folder with fits reports>"
  exit
end

folder=ARGV[0]
conflict_table={}
mimetype=""

Find.find(folder) do |file|
  if FileTest.file?(file)
    #    puts "file found: #{file}"
    File.open(file,"r").each do |line|
      #      puts "line: #{line}"
      if line.match(/mimetype=\"([a-zA-Z\/]*)\"/)
        mimetype = $1
        puts "mimetype found: #{mimetype}"
      end
      if line.match(/<([a-zA-Z]*).*status=\"CONFLICT\"/)
        #        puts "conflict found: #{line}"
        puts "\tconflict found: #{$1}"
        counter = conflict_table[mimetype].to_i+1
        conflict_table.store(mimetype, counter)
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