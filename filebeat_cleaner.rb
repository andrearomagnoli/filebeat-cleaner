#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'optparse'
require 'fileutils'

registry_path = '/var/lib/filebeat/registry'
move_path = '/opt/data/filebeat/done'

# Command line options start
options = { verbose: false, summary: false, move: true }
opt_parser = OptionParser.new do |opt|
  opt.banner = 'Usage: ruby log_rotate.rb [options]'
  opt.on( '-f', '--file REGISTRY', 'Full path to the registry file (default /var/lib/filebeat/registry)' ) do |registry|
    registry_path = registry.chomp('/')
  end
  opt.on( '-d', '--directory TARGET', 'Directory where files are moved (default /opt/data/filebeat/done)' ) do |move|
    move_path = move.chomp('/')
  end
  opt.on( '-v', '--verbose', 'Verbose output logging' ) do
    options[:verbose] = true
    options[:summary] = true
  end
  opt.on( '-m', '--move', 'Does not move any log file' ) do
    options[:move] = false
  end
  opt.on( '-s', '--summary', 'Summary of I/O operations' ) do
    options[:summary] = true
  end
  opt.on( '-h', '--help', 'Show help' ) do
    puts opt_parser
    exit
  end
end
opt_parser.parse!
# Command line options end

if options[:summary] then
  count_move = 0
  count_notfound = 0
  count_read = 0
  tot_percent = 0.0
  percent_shift = Hash.new(0)
end

if options[:verbose]
  puts "\n*** VERBOSE ***\n\n"
  puts "registry_path: '#{registry_path}'"
  puts "move_path: '#{move_path}'"
end

# Read data registry, and parse the JSON
if File.exist?( registry_path ) then
  # Check if a logfiles is already in the registry
  JSON.parse( File.read( registry_path )).each do |record|
    # If the filename exists only in the registry, wait for Prospector
    if not File.exist?(record['source']) then
      if options[:verbose] then
        puts "File '#{record['source']}' not found. FileBeats Prospector will delete the registry entry..."
      end
      if options[:summary] then
        count_notfound = count_notfound + 1
      end
    # Move the file in the registry, if it has been read completely
    elsif record['offset'] == File.size(record['source']) then
      if options[:move] then
        FileUtils.mkdir_p(move_path) unless File.exists?(move_path)
        FileUtils.move( record['source'], move_path )
      end
      if options[:verbose] then
        if options[:move] then
          puts "** MOVED ** right now '#{record['source']}'"
        else
          puts "** SHOULD BE MOVED ** right now '#{record['source']}'"
        end
      end
      if options[:summary] then
        count_move = count_move + 1
      end
    # Show progress if still reading the file (useful for debugging)
    else
      percent = ( record['offset'].to_f/File.size(record['source']).to_f * 100 ).round(2)
      if options[:verbose] then
        puts "Reading...\t#{percent} %\n- File: #{record['source']}"
      end
     if options[:summary] then
        count_read = count_read + 1
        tot_percent = tot_percent + percent
        case (record['offset'].to_f/File.size(record['source']).to_f * 100).round
        when 0...20
          percent_shift[0] += 1
        when 20...40
          percent_shift[20] += 1
        when 40...60
          percent_shift[40] += 1
        when 60...80
          percent_shift[60] += 1
        when 80..100
          percent_shift[80] += 1
        end
      end
    end
  end
# If the data/registry doesn't exists, FileBeats will create it
else
  print "Registry file doesn't exist"
  if options[:verbose] then
    print ". Wait for FileBeats to create a new file.."
  end
  print ".\n"
end

# Post-processing
if options[:summary] then
  puts "\n*** SUMMARY ***\n\n"
  if options[:move] then
    puts "Moved files:    \t#{count_move}"
  else
    puts "Movable files:  \t#{count_move}"
  end
  puts "Files not found:  \t#{count_notfound}"
  puts "Reading files:    \t#{count_read}"
  if count_read != 0 then
    tot_percent = (tot_percent / count_read.to_f).round(2)
    puts "Reading progress: \t#{tot_percent} % (average)"
  end
  percent_shift.sort_by{ |k,v| k }.each do |k, v|
    puts " - #{k}%:\t#{v} files"
  end
  puts
end
