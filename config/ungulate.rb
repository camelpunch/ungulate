require 'ungulate'

Ungulate.configure do |config|
  # Configure your queue runner here.
  #
  # If you're just using the upload helpers within a Rails application, you
  # should instead create an initializer e.g. config/initializers/ungulate.rb
  # with the same contents as this file.
  #
  # Note: you can optionally set AMAZON_ACCESS_KEY_ID and
  # AMAZON_SECRET_ACCESS_KEY as environment variables from the environment.
  # These will be overridden if set in the config file.
  #
  # config.access_key_id = 'ASDFASDFASDF'
  # config.secret_access_key = 'ASDFASDFASDF'
  # config.queue_name = 'my-lovely-queue'
  # config.queue_server = 'sqs.eu-west-1.amazonaws.com'
  # config.s3_region = 'eu-west-1' # optional, defaults to us-east-1

  config.server_sleep = 2 # seconds

  # Test settings
  # config.test_bucket = 'ungulate-test'
  # config.test_upload_key = 'some-file'
  # config.test_success_action_redirect_path = '/some-path'
  # config.test_queue_name = 'some-queue'

  #
  # Advanced:
  #
  # You can change the classes used by Ungulate to perform certain operations,
  # for example if you wanted to do image processing differently, write your own
  # class and instantiate in a lambda as follows:
  #
  # config.version_creator = lambda {
  #   GreatGraphicsLibraryVersionCreator.new(:http => config.http.call)
  # }
  #
  # Above, config.http.call is referencing the currently configured http class.
  #
  # To use your own classes, just make sure they have the same API as the ones
  # currently in Ungulate. You should write tests to make sure of this, based on
  # the ones in Ungulate!
  #
  # You can pass the path to your config file to the -c argument of
  # ungulate_server.rb
end
