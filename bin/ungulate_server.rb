#!/usr/bin/env ruby

require 'ungulate/server'

if ARGV[0].nil?
  $stderr.puts "Must provide a queue name after calling the server"
  exit 1
end

logger = Logger.new $stderr

loop do
  begin
    processed_something = Ungulate::Server.run(ARGV[0]) 
    sleep(ENV['SLEEP'] || 2) unless processed_something
  rescue StandardError => e
    logger.error e.message
  end
end
