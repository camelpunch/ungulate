Given /^an empty queue$/ do
  sqs = RightAws::SqsGen2.new(ENV['AMAZON_ACCESS_KEY_ID'],
                              ENV['AMAZON_SECRET_ACCESS_KEY'])
  @queue_name = 'ungulate-test-queue'
  @q = sqs.queue @queue_name
  @q.clear
end

Given /^a request to resize "([^\"]*)" to sizes:$/ do |key, table|
  bucket_name = "ungulate-test"

  @s3 = RightAws::S3.new(ENV['AMAZON_ACCESS_KEY_ID'],
                         ENV['AMAZON_SECRET_ACCESS_KEY'])
  @bucket = @s3.bucket bucket_name
  @bucket.put key, File.open('features/camels.jpg').read


  versions = table.rows.inject({}) do |hash, row|
    label, width, height = row
    hash[label] = [:resize_to_fit, width, height]
    hash
  end

  message = {
    :bucket => bucket_name,
    :key => key,
    :versions => versions
  }.to_yaml

  @q.send_message(message)
end

