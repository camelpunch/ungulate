require 'right_aws'

def storage
  if Ungulate.configuration.test_bucket.blank?
    raise Ungulate::MissingConfiguration,
      "Please set config.test_bucket to run Cucumber features"
  end

  @storage ||= Fog::Storage.new(
    :provider => 'AWS',
    :aws_access_key_id => Ungulate.configuration.access_key_id,
    :aws_secret_access_key => Ungulate.configuration.secret_access_key,
    :region => 'eu-west-1'
  )
end

def put(key, value)
  storage.put_object Ungulate.configuration.test_bucket, key, value
end

def sqs
  RightAws::SqsGen2.new(Ungulate.configuration.access_key_id,
                        Ungulate.configuration.secret_access_key,
                        :server => Ungulate.configuration.queue_server)
end

def test_queue_name
  if Ungulate.configuration.test_queue_name.blank?
    raise Ungulate::MissingConfiguration,
      "Please set config.test_queue_name to run Cucumber features"
  end

  Ungulate.configuration.test_queue_name
end

def queue
  @queue ||= sqs.queue(test_queue_name)
end

