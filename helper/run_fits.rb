# encoding: utf-8

require 'find'
require 'timeout'

if ARGV.size != 1
  puts "usage: ruby tool.rb <folder to check>"
  exit
end

folder=ARGV[0]
max_threads=10
timeout=2
timeout_thread=60
fits="/mnt/daten1/privat/uni/aktuell/Digital Preservation/ue/assignment 2/topic 1/fits_modified/git/fits/fits.sh"
output_folder="/mnt/daten1/privat/uni/aktuell/Digital Preservation/ue/assignment 2/topic 1/fits_modified/reports"
threads={}

counter = 0

def to_much_threads(t,max)
  puts "refresh thread list"
  t.each do |key,thread|
    if !thread.status
      puts "remove thread from list: #{key}"
      t.delete(key)
    end
  end
  puts "check threads, currently: #{t.size}"
  if t.size >= max
    puts "true"
    true
  else
    puts "false"
    false
  end
end

Find.find(folder) do |file|
  if FileTest.file?(file)
    file_fits_xml=File.join(output_folder,file.gsub(/\//, "_"))+".fits.xml"
    if ! FileTest.file?(file_fits_xml)
      # start fits i a new thread
      thread = Thread.new do
        Timeout::timeout(timeout_thread) do
          `"#{fits}" -i "#{file}" -o "#{file_fits_xml}"`
        end
      end
      # store threads
      threads.store(thread.to_s, thread)
      # check if to many threads are running
      while to_much_threads(threads,max_threads)
        sleep(timeout)
      end
      counter += 1
    else
      puts "already checked: #{file_fits_xml}"
    end
  end
end

#wait for threads to be finished
puts "waiting for threads to be finished"
threads.each do |key,thread|
  thread.join;
end
puts "finished"

puts "counter: #{counter}"
