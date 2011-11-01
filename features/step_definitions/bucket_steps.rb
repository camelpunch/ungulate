Given /^an empty bucket$/ do
  bucket = storage.get_bucket(BUCKET_NAME)
  key_names = bucket.body['Contents'].map {|h| h['Key'] }

  key_names.each do |key|
    storage.delete_object(BUCKET_NAME, key)
  end
end

