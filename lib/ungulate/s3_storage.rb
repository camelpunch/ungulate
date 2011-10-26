module Ungulate
  class S3Storage
    def initialize(options)
      @s3 = RightAws::S3.new *options.values_at(:access_key_id, :secret_access_key)
    end

    def bucket(name, options = {})
      S3Bucket.new(@s3, name, options)
    end
  end

  class S3Bucket
    def initialize(s3, name, options = {})
      @bucket = s3.bucket(name)
      @listener = options[:listener]
    end

    def store(key, value, options = {})
      @bucket.put(key, value)

      if @listener && options[:version]
        @listener.storage_complete(options[:version])
      end
    end

    def retrieve(key)
      @bucket.get(key)
    end

    def clear
      @bucket.clear
    end
  end
end
