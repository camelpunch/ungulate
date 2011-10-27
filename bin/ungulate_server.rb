#!/usr/bin/env ruby

require File.expand_path('../lib/ungulate', File.dirname(__FILE__))

logger = Logger.new $stderr

loop do
  begin
    processed_something = Ungulate::Server.run
    sleep(ENV['SLEEP'] || 2) unless processed_something
  rescue Ungulate::MissingConfiguration => e
    logger.error e.message
    exit 1
  rescue StandardError => e
    logger.error e.message
  end
end
