module Ungulate
  class SqsMessageQueue
    class Message
      def initialize(sqs, queue_url, data)
        @sqs = sqs
        @queue_url = queue_url
        @data = data
      end

      def delete
        @sqs.delete_message(@queue_url, @data['ReceiptHandle'])
      end

      def to_s
        @data['Body']
      end
    end

    def initialize(name, options)
      if name.blank?
        raise Ungulate::MissingConfiguration,
          "queue_name must be set in config"
      end

      @name = name
      @sqs = Fog::AWS::SQS.new(
        :aws_access_key_id => options[:access_key_id],
        :aws_secret_access_key => options[:secret_access_key],
        :host => options[:server]
      )
      @queue_url = @sqs.create_queue(name).body['QueueUrl']
    end

    def name
      @name
    end

    def clear
      loop do
        receive.tap do |message|
          return true if message.nil?
          message.delete
        end
      end
    end

    def push(message)
      @sqs.send_message(@queue_url, message)
    end

    def receive
      data = @sqs.receive_message(@queue_url).body
      return nil if data['Message'].first.blank?
      Message.new(@sqs, @queue_url, data['Message'].first)
    end

    def size
      data = @sqs.get_queue_attributes(@queue_url, 'All').body['Attributes']
      data['ApproximateNumberOfMessages'].
        try(:+, data['ApproximateNumberOfMessagesNotVisible'])
    end
  end
end
