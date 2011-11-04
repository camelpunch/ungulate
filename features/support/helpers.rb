require 'right_aws'

def storage
  @storage ||= Fog::Storage.new(
    :provider => 'AWS',
    :aws_access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
    :aws_secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'],
    :region => 'eu-west-1'
  )
end

def put(key, value)
  storage.put_object Ungulate.configuration.test_bucket, key, value
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
