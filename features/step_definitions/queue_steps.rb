Given /^an empty queue$/ do
  queue.clear
end

Given /^a request to resize "([^\"]*)" to sizes:$/ do |key, table|
  put key, File.open('features/camels.jpg').read

  versions = table.rows.inject({}) do |hash, row|
    label, width, height = row
    hash[label] = [:resize_to_fit, width, height]
    hash
  end

  message = {
    :bucket => Ungulate.configuration.test_bucket,
    :key => key,
    :versions => versions
  }.to_yaml

  queue.send_message(message)
end

Given /^a request to resize "([^"]*)" and then composite with "([^"]*)"$/ do |key, composite_url|
  put key, File.open('features/camels.jpg').read

  message = {
    :bucket => Ungulate.configuration.test_bucket,
    :key => key,
    :versions => {
      :watermarked => [
        [:resize_to_fill, 100, 100],
        [:composite, composite_url, :center_gravity, :soft_light_composite_op]
      ]
    }
  }.to_yaml

  queue.send_message(message)
end
