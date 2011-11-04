require 'capybara/cucumber'

def path_to_file
  File.expand_path('../../spec/fixtures/chuckle.png', File.dirname(__FILE__))
end

Given /^an Ungulate form rendered with a success redirect$/ do
  Capybara.app = TestApp
  visit '/'
end

When /^I attach a file to the form$/ do
  attach_file "file", path_to_file
end

When /^I submit the form$/ do
  if Ungulate.configuration.test_bucket.blank?
    raise RuntimeError,
      "Please set config.test_bucket to run FileUpload Cucumber features"
  end

  if Ungulate.configuration.test_upload_key.blank?
    raise RuntimeError,
      "Please set config.test_upload_key to run FileUpload Cucumber features"
  end

  if Ungulate.configuration.test_success_action_redirect_path.blank?
    raise RuntimeError,
      "Please set config.test_success_action_redirect_path to run FileUpload Cucumber features"
  end

  click_button 'submit'
end

Then /^I should be taken to the success redirect URL$/ do
  expected_url =
    "http://localhost:9999#{Ungulate.configuration.test_success_action_redirect_path}"
  current_url.should match(/^#{expected_url}/)
end

Then /^the file I uploaded should be on S3$/ do
  storage.get_object(
    Ungulate.configuration.test_bucket,
    Ungulate.configuration.test_upload_key
  ).body.should == File.read(path_to_file)
end

Then /^show me the page$/ do
  save_and_open_page
end

