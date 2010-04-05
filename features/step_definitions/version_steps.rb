Then /^there should be the following public versions:$/ do |table|
  Net::HTTP.start("#{@bucket_name}.s3.amazonaws.com", 80) do |http|
    table.rows.flatten.each do |key|
      response = http.get("/#{key}")
      response.should be_a(Net::HTTPSuccess)
    end
  end
end

