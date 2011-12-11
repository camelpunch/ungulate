require 'net/http'

Then /^there should be the following public versions:$/ do |table|
  Net::HTTP.start("#{Ungulate.configuration.test_bucket}.s3.amazonaws.com", 80) do |http|
    table.rows.flatten.each do |key|
      response = http.get("/#{key}")
      response.should be_a(Net::HTTPSuccess)
    end
  end
end

Then /^there should be a public watermarked version$/ do
  Net::HTTP.start("#{Ungulate.configuration.test_bucket}.s3.amazonaws.com", 80) do |http|
    response = http.get("/image_watermarked.jpg")
    response.should be_a(Net::HTTPSuccess)
  end
end

Then /^the "([^"]*)" version should have a smaller file than the "([^"]*)" version$/ do |first, second|
  first_size = nil
  second_size = nil

  Net::HTTP.start("#{Ungulate.configuration.test_bucket}.s3.amazonaws.com", 80) do |http|
    response = http.get("/some/path/to/image_#{first}.jpg")
    first_size = response.body.size
  end

  Net::HTTP.start("#{Ungulate.configuration.test_bucket}.s3.amazonaws.com", 80) do |http|
    response = http.get("/some/path/to/image_#{second}.jpg")
    second_size = response.body.size
  end

  first_size.should < second_size
end

