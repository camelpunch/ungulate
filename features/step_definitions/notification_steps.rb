Given /^a request that has a notification URL$/ do
  key = 'bobbyjpeg'

  put key, File.open('features/camels.jpg').read

  message = {
    :bucket => Ungulate.configuration.test_bucket,
    :key => key,
    :notification_url => 'http://127.0.0.1:9999/bob',
    :versions => {
      :medium => [
        [:resize_to_fill, 100, 100],
      ]
    }
  }.to_yaml

  queue.push(message)
end

Then /^the notification URL should receive a PUT$/ do
  File.read(TEST_FILE.path).should == 'http://127.0.0.1:9999/bob'
end

