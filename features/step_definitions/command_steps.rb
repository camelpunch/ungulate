require 'ostruct'
require 'ungulate'

When /^I run Ungulate$/ do
  @errors = OpenStruct.new :write => ''
  $stderr = @errors

  queue = Ungulate::SqsMessageQueue.new(
    QUEUE_NAME,
    :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'],
    :server => sqs_server
  )

  storage = Ungulate::S3Storage.new(
    :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
  )

  Ungulate::Server.new(
    :queue => queue,
    :job_processor => Ungulate::Job.new(
      :blob_processor => Ungulate::BlobProcessor.new(
        :version_creator => Ungulate::RmagickVersionCreator.new(
          :http => Ungulate::CurlHttp.new
        )
      ),
      :storage => storage,
      :http => Ungulate::CurlHttp.new
  )).run
end

Then /^there should be no errors$/ do
  @errors.write.should be_empty
end

