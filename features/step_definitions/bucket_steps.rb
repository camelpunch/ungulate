Given /^an empty bucket$/ do
  bucket = storage.get_bucket(Ungulate.configuration.test_bucket)
  key_names = bucket.body['Contents'].map {|h| h['Key'] }

  key_names.each do |key|
    storage.delete_object(Ungulate.configuration.test_bucket, key)
  end
end

