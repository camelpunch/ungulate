Given /^a request that has a notification URL$/ do
  key = 'bobbyjpeg'

  put key, File.open('features/camels.jpg').read

  message = {
    :bucket => BUCKET_NAME,
    :key => key,
    :notification_url => 'http://localhost:9999/bob',
    :versions => {
      :medium => [
        [:resize_to_fill, 100, 100],
      ]
    }
  }.to_yaml

  send_message(message)
end

Then /^the notification URL should receive a PUT$/ do
  File.read(TEST_FILE.path).should == 'http://localhost:9999/bob'
end
