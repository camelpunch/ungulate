When /^I run Ungulate$/ do
  @errors = OpenStruct.new :write => ''
  $stderr = @errors
  Ungulate::Server.run @queue_name
end

Then /^there should be no errors$/ do
  @errors.write.should be_empty
end

