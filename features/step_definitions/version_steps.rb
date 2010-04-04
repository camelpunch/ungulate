Then /^there should be the following versions:$/ do |table|
  table.rows.flatten.each do |key|
    @bucket.get(key).should_not be_empty
  end
end

