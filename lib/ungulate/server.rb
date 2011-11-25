require 'logger'

module Ungulate
  class Server
    def initialize(options = {})
      @logger = options[:logger] || ::Logger.new($stdout)
      @job_processor = options[:job_processor]
      @queue = options[:queue]
    end

    class << self
      def config
        Ungulate.configuration
      end

      def run
        new(
          :job_processor => config.job_processor.call,
          :queue => config.queue.call
        ).run
      end
    end

    def run
      @logger.info "Checking for job on #{@queue.name}"
      message = @queue.receive

      if message
        @job_processor.process(message.to_s)
        message.delete
        true
      end
    end
  end
end

