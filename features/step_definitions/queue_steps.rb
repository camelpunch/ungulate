Given /^an empty queue$/ do
  @q = sqs.queue QUEUE_NAME
  @q.clear
end

Given /^a request to resize "([^\"]*)" to sizes:$/ do |key, table|
  old_size = @q.size

  bucket.put key, File.open('features/camels.jpg').read

  versions = table.rows.inject({}) do |hash, row|
    label, width, height = row
    hash[label] = [:resize_to_fit, width, height]
    hash
  end

  message = {
    :bucket => BUCKET_NAME,
    :key => key,
    :versions => versions
  }.to_yaml

  @q.send_message(message)

  puts "waiting for message to reach queue"
  while @q.size == old_size do
    sleep 1
  end
end

Given /^a request to resize "([^"]*)" and then composite with "([^"]*)"$/ do |key, composite_url|
  bucket.put key, File.open('features/camels.jpg').read

  message = {
    :bucket => BUCKET_NAME,
    :key => key,
    :versions => {
      :watermarked => [
        [:resize_to_fill, 100, 100],
        [:composite, composite_url, :center_gravity, :soft_light_composite_op]
      ]
    }
  }.to_yaml

  @q.send_message(message)
end
