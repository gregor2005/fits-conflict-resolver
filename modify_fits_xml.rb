require 'find'
require 'libxml'

if ARGV.size != 4
  puts "usage: ruby tool.rb <rule.conf> <folder with fits reports> <empty folder to store backups> <fits xsd>"
  exit
end

rules_config = ARGV[0]
folder = ARGV[1]
backup_folder = ARGV[2]
@fits_xsd = ARGV[3]

@mimetype = ""
@version = ""
@field = ""
prevent_tool = ""
tool_version = ""
rules = []

class Rule
  attr_accessor :name, :mimetype, :version, :field, :prevent_tool, :tool_version
  def to_string
    "rule: #{mimetype}, #{version}, #{field}, #{prevent_tool}, #{tool_version}"
  end
end

# check if backup folder exists
if !FileTest.directory?(backup_folder)
  puts "!!! backup folder does not exists, folder: #{backup_folder} !!!"
  exit
end

# check if fits xsd exists
if !FileTest.file?(@fits_xsd)
  puts "!!! fits xsd is no file: #{@fits_xsd}"
  exit
end

# check if rules config exists
if !FileTest.file?(rules_config)
  puts "!!! rulesfile is no file: #{rules_config}"
  exit
end

# store the rule
File.open(rules_config, "r").each do |line|
  if line.match(/^.*#.*/)
    puts "comment found: #{line}"
  else
    puts "rule found: #{line}"
    parts = line.split(',')
    if parts.size == 6
      # store rule
      rule = Rule.new
      rule.name = parts[0].chomp
      rule.mimetype = parts[1].chomp
      rule.version = parts[2].chomp
      rule.field = parts[3].chomp
      rule.prevent_tool = parts[4].chomp
      rule.tool_version = parts[5].chomp
      rules << rule
    else
      puts "rule does not have 6 parts"
      puts "error rule: #{line}"
      puts "\tsyntax: mimetype,version,conflicted field,prevent tool,tool version"
      puts "\texample: application/pdf,1.4,creatingApplicationName,Jhove,1.5"
    end
  end
end

# method to make xml backups
def do_backup(filename,backup_folder,rulename)
  if FileTest.file?(filename)
    if FileTest.file?(File.join(backup_folder,filename))
      puts "!!! backupfile already exists, please choose another backup folder, file: #{File.join(backup_folder,filename)}"
      exit
    end
    backup_rule_folder = File.join(backup_folder,rulename)
    if !FileTest.directory?(backup_rule_folder)
      `mkdir #{backup_rule_folder}`
    end
    `cp #{filename} #{backup_rule_folder}/`
    # TODO check return value
  else
    puts "!!! do_backup file does not exists: #{filename}"
    exit
  end
end

# method to check xml consistency
def check_xml(filename)
  # TODO verursacht bei rule2 ein problem
  document = LibXML::XML::Document.file(filename)
  schema = LibXML::XML::Schema.new(@fits_xsd)
  result = document.validate_schema(schema) do |message,flag|
    puts "!!! error found: #{message}"
    exit
  end
end

# method to generate new xml file
def write_new_file(filename,xml_content)
  if FileTest.file?(filename)
    file = File.new(filename,"w")
    xml_content.each do |line|
      file.puts(line)
    end
    file.close
    puts "new file generated: #{filename}"
#    check_xml(filename) TODO resolve problem, see method
  else
    puts "!!! do_backup file does not exists: #{filename}"
    exit
  end
end

# method to remove conflict status
def remove_conflict_status(rule, xml_content_old)
  xml_content = []
  found_mimetype = false
  found_version = false
  #  File.open(file,"r").each do |line|
  xml_content_old.each do |line|
    if line.match(/mimetype=\"(#{rule.mimetype})\"/)
      mimetype = $1
      found_mimetype = true
    end
    if found_mimetype
      if (line.match(/.*version.*>#{rule.version}<\/version>/))
        found_version = true
      end
    end
    if found_mimetype && found_version
      if line.match(/<#{rule.field} toolname=\"(.*)\" toolversion=\"(.*)\" .*status=\"CONFLICT\"/)
        # remove conflict status
        line = line.gsub(/ status=\"CONFLICT\"/, "")
        @removed_status_counter = @removed_status_counter + 1
      end
    end
    xml_content << line
  end
  return xml_content
end

@removed_status_counter = 0

# apply the rules
rules.each do |rule|
  puts "apply rule: #{rule.to_string}"
  conflict_counter = 0
  Find.find(folder) do |file|
    if FileTest.file?(file)
      puts "file: #{file}"
      xml_content = []
      found_mimetype = false
      found_field = false
      found_version = false
      line_was_removed = false
      found_conflict = 0
      File.open(file,"r").each do |line|
        remove_line = false
        if line.match(/mimetype=\"(#{rule.mimetype})\"/)
          mimetype = $1
          found_mimetype = true
        end
        if found_mimetype
          if (line.match(/.*version.*>#{rule.version}<\/version>/))
            found_version = true
          end
        end
        if found_mimetype && found_version
          if line.match(/<#{rule.field} toolname=\"(.*)\" toolversion=\"(.*)\" .*status=\"CONFLICT\"/)
            found_conflict = found_conflict+1
            tool = $1
            tool_version = $2
            puts "~~~~~~~~~~~~~~~~~~~found tool: #{tool}, #{tool_version}"
            #          puts "found tool version: #{tool_version}"
            puts "#{rule.mimetype} #{rule.field} #{rule.version}, #{rule.prevent_tool}, #{rule.tool_version}"
            #          puts "found example file: #{file}"
            if tool == rule.prevent_tool && tool_version == rule.tool_version
              found_conflict = found_conflict-1
              remove_line = true
            end
          end
        end
        if !remove_line
          xml_content << line
        else
          conflict_counter = conflict_counter + 1
          line_was_removed = true
        end
      end

#      if found_conflict > 1
#        puts "more than one conflict found"
        # do nothing because some conflicts still exists in that field
#      end

      if found_conflict == 1 && line_was_removed
        puts "only one conflict found"
        xml_content = remove_conflict_status(rule, xml_content)
        do_backup(file,backup_folder,rule.name)
        write_new_file(file,xml_content)
      end

      if found_conflict > 1  && line_was_removed
        puts "found conflicts: #{found_conflict}"
        do_backup(file,backup_folder,rule.name)
        write_new_file(file,xml_content)
        #              puts "------print new file: #{file}-----------"
        #      File.open(file,"r").each do |new_line|
        #        puts "xml line: #{new_line}"
        #      end
        #              xml_content.each do |xml_line|
        #                puts"xml line: #{xml_line}"
        #              end
        #              puts "----------------------------------------"
        #              exit
      end
    end
  end
  puts "removed conflicts for rule #{rule.name} is: #{conflict_counter}"
  puts "removed status conflicts for rule #{rule.name} is: #{@removed_status_counter}"
end

# TODO check if XML has errors

#conflict_table = conflict_table.sort_by { |key, value| value }.reverse
#
#sum = 0
#
#conflict_table.each do |key,value|
#  puts "#{key}: #{value}"
#  sum = sum + value
#end
#
#puts "sum: #{sum}"