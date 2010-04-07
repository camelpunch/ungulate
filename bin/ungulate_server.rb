#!/usr/bin/env ruby

require 'ungulate'

if ARGV[0].nil?
  $stderr.puts "Must provide a queue name after calling the server"
  exit 1
end

logger = Logger.new STDERR

loop do
  begin
    sleep 1
    Ungulate.run(ARGV[0]) 
  rescue StandardError => e
    logger.error e.message
  end
end
