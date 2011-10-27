require 'right_aws'

def bucket
  s3 = RightAws::S3.new(ENV['AMAZON_ACCESS_KEY_ID'],
                        ENV['AMAZON_SECRET_ACCESS_KEY'])
  s3.bucket BUCKET_NAME
end

def sqs_server
  'sqs.eu-west-1.amazonaws.com'
end

def sqs
  sqs = RightAws::SqsGen2.new(ENV['AMAZON_ACCESS_KEY_ID'],
                              ENV['AMAZON_SECRET_ACCESS_KEY'],
                              :server => sqs_server)
end

def send_message(message)
  @q.send_message message
end
