require 'ostruct'
require 'ungulate'

When /^I run Ungulate$/ do
  @errors = OpenStruct.new :write => ''
  $stderr = @errors

  Ungulate.configure do |config|
    config.queue_name = test_queue_name
  end

  10.times do
    break if Ungulate::Server.run
  end
end

Then /^there should be no errors$/ do
  @errors.write.should be_empty
end

