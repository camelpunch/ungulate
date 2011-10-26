require 'spec_helper'
require 'ungulate/sqs_message_queue'

# integration test - talks to real queue
#
# to spec a new message queue, copy this spec and change the require and
# describe lines, and change new_queue to instantiate your queue class
# message queues are always passed the options below, from the environment
#
# note that you'll probably need to wrap the messages returned from your queue
# to behave like messages from SQS, i.e. they need to implement 'to_s' to convert
# them to a string, and 'delete' to delete them from the queue
module Ungulate
  describe SqsMessageQueue do
    def new_queue
      SqsMessageQueue.new('some_test_queue',
                          :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
                          :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'],
                          :server => ENV['QUEUE_SERVER'])
    end

    it_behaves_like "a message queue"
  end
end
