#!/usr/bin/env ruby

require File.expand_path('../../lib/ungulate', __FILE__)
require 'optparse'

logger = Logger.new $stderr

options = {
  :config => File.expand_path('../../config/ungulate', __FILE__)
}

cmdline_options = OptionParser.new do |opts|
  opts.banner = "Usage: ungulate_server.rb [options]"

  opts.on '-c', '--config CONFIG' do |config|
    options[:config] = config
  end
end

cmdline_options.parse!

require options[:config]

loop do
  begin
    processed_something = Ungulate::Server.run
    sleep(Ungulate.configuration.server_sleep || 2) unless processed_something
  rescue Ungulate::MissingConfiguration => e
    logger.error e.message
    exit 1
  rescue StandardError => e
    logger.error e.message
  end
end
