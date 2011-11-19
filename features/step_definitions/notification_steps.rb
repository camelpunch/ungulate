Given /^a request that has a notification URL$/ do
  key = 'bobbyjpeg'

  put key, File.open('features/camels.jpg').read

  message = {
    :bucket => Ungulate.configuration.test_bucket,
    :key => key,
    :notification_url => 'http://127.0.0.1:4567/bob',
    :versions => {
      :medium => [
        [:resize_to_fill, 100, 100],
      ]
    }
  }.to_yaml

  queue.push(message)

  File.unlink('/tmp/ungulate_put_test') rescue

  # start sinatra app
  @sinatra_pid = fork do
    TestApp.run!
  end
end

Then /^the notification URL should receive a PUT$/ do
  File.read('/tmp/ungulate_put_test').should == 'received, loud and clear!'
  Process.kill('KILL', @sinatra_pid)
  File.unlink('/tmp/ungulate_put_test')
end
