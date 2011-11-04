require 'ostruct'
require 'ungulate'

When /^I run Ungulate$/ do
  @errors = OpenStruct.new :write => ''
  $stderr = @errors

  Ungulate.configure do |config|
    if config.test_queue_name.blank?
      raise Ungulate::MissingConfiguration,
        "Please set config.test_queue_name to run Cucumber features"
    end
    config.queue_name = config.test_queue_name
  end

  10.times do
    break if Ungulate::Server.run
  end
end

Then /^there should be no errors$/ do
  @errors.write.should be_empty
end

