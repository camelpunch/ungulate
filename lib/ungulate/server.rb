require 'logger'

module Ungulate
  class Server
    def initialize(options = {})
      @logger = options[:logger] || ::Logger.new($stdout)
      @job_processor = options[:job_processor]
      @queue = options[:queue]
    end

    def run
      @logger.info "Checking for job on #{@queue.name}"
      message = @queue.receive

      if message
        success = @job_processor.process(message.to_s)
        message.delete
        success
      end
    end
  end
end

