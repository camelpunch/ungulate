require 'right_aws'

module Ungulate
  class SqsMessageQueue
    def initialize(name, options)
      sqs = RightAws::SqsGen2.new(
        options[:access_key_id], options[:secret_access_key],
        :server => options[:server]
      )
      @queue = sqs.queue name
    end

    def name
      @queue.name
    end

    def clear
      @queue.clear
    end

    def push(message)
      @queue.push(message)
    end

    def receive
      @queue.receive
    end

    def size
      @queue.size
    end
  end
end
