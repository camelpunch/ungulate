require 'fog'

module Ungulate
  class S3Storage
    def initialize(options)
      @storage = Fog::Storage.new(
        :provider => 'AWS',
        :aws_access_key_id => options[:access_key_id],
        :aws_secret_access_key => options[:secret_access_key],
        :region => options[:region]
      )
    end

    def bucket(name, options = {})
      S3Bucket.new(@storage, name, options)
    end
  end

  class S3Bucket
    def initialize(storage, name, options = {})
      @storage = storage
      @bucket_name = name
      @listener = options[:listener]
      @logger = options[:logger] || ::Logger.new($stdout)
    end

    def store(key, value, options = {})
      @logger.info "Storing #{key} with size #{value.size}, content-type #{options[:content_type]}"

      @storage.put_object(@bucket_name, key, value, {
        'Content-Type' => options[:content_type],
        'Cache-Control' => 'max-age=2629743',
        'x-amz-acl' => 'public-read'
      })

      if @listener && options[:version]
        @listener.storage_complete(options[:version])
      end
    end

    def retrieve(key)
      @logger.info "Retrieving #{key}"
      @storage.get_object(@bucket_name, key).body
    end

    def delete(key)
      @storage.delete_object(@bucket_name, key)
    end
  end
end
