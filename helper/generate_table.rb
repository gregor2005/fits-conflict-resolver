require 'find'

if ARGV.size != 1
  puts "usage: ruby tool.rb <folder with fits reports>"
  exit
end

folder=ARGV[0]

def find_mimetype(folder)
  conflict_table={}
  mimetype=""
  Find.find(folder) do |file|
    if FileTest.file?(file)
      #    puts "file found: #{file}"
      File.open(file,"r").each do |line|
        #      puts "line: #{line}"
        if line.match(/mimetype=\"([a-zA-Z\/]*)\"/)
          mimetype = $1
          #        puts "mimetype found: #{mimetype}"
        end
        if line.match(/<([a-zA-Z]*).*status=\"CONFLICT\"/)
          #        puts "\tconflict found: #{$1}"
          counter = conflict_table[mimetype].to_i+1
          conflict_table.store(mimetype, counter)
        end
      end
    end
  end
  conflict_table.sort_by { |key, value| value }.reverse
end

conflict_table = {}
conflict_table = find_mimetype(folder)

sum = 0

puts "--- mimetypes ---"

conflict_table.each do |key,value|
  puts "#{key}: #{value}"
  sum = sum + value
end

puts "-----------------"

puts "sum of found conflicted mimetypes: #{sum}"

mimetype = conflict_table[0].first;

puts "top mimetype: #{mimetype}"

def find_field(folder,mimetype)
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
        if line.match(/<(\w*) .*status=\"CONFLICT\"/)
          field = $1
          if found_mimetype
            counter = conflict_table[field].to_i+1
            conflict_table.store(field, counter)
          end
        end
      end
    end
  end
  conflict_table.sort_by { |key, value| value }.reverse
end

conflict_table = {}
conflict_table = find_field(folder,mimetype)

sum = 0

puts "--- field ---"

conflict_table.each do |key,value|
  puts "#{key}: #{value}"
  sum = sum + value
end

puts "-------------"

puts "sum of found conflicted field for mimetype: #{mimetype}, sum: #{sum}"

field = conflict_table[0].first;

puts "top field: #{field}"

def find_version(folder,mimetype,field)
  conflict_table={}
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
            value = conflict_table[version]
            if value==nil
              value = []
              value << 1
              value << file
            else
              value[0] = value[0].to_i+1
              value[1] = file
            end
            conflict_table.store(version, value)
#            puts "--------store: #{value[0]}, #{value[1]}"
          end
        end
      end
    end
  end
  conflict_table.sort_by { |key, value| value }.reverse
end

conflict_table = {}
conflict_table = find_version(folder,mimetype,field)

sum = 0

puts "--- version ---"

conflict_table.each do |key,value|
  puts "#{key}: #{value[0]}"
  sum = sum + value[0]
end

puts "---------------"

puts "sum of found conflicted version for mimetype: #{mimetype} and field #{field}, sum: #{sum}"

version = conflict_table[0].first;

puts "top version: #{version}"

puts "example file: #{conflict_table[0][1][1]}"