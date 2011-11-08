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

