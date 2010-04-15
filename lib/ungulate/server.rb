require 'logger'
require 'ungulate/job'

module Ungulate
  module Server
    def self.logger
      @logger ||= ::Logger.new STDOUT
    end

    def self.run(queue_name)
      logger.info "Checking for job on #{queue_name}"
      Job.pop(queue_name).process
    end
  end
end

