require 'ostruct'
require 'ungulate'
require 'config/ungulate'

When /^I run Ungulate$/ do
  @errors = OpenStruct.new :write => ''
  old_stderr = $stderr
  $stderr = @errors

  Ungulate.configure do |config|
    config.queue_name = test_queue_name
  end

  10.times do
    Ungulate::Server.run
  end

  $stderr = old_stderr
end

Then /^there should be no errors$/ do
  @errors.write.should be_empty
end

