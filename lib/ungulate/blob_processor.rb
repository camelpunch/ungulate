module Ungulate
  class BlobProcessor
    def initialize(options)
      @creator = options[:version_creator]
    end

    def process(options)
      versions = options.delete(:versions)
      blob = options.delete(:blob)
      original_key = options.delete(:original_key)
      bucket = options.delete(:bucket)

      versions.each_pair do |name, instructions|
        stored_data = @creator.create(blob, instructions)

        bucket.store(
          new_key(original_key, name),
          stored_data[:blob],
          :version => name,
          :content_type => stored_data[:content_type]
        )
      end
    end

    protected

    def new_key(original, version)
      dirname = File.dirname(original)
      extname = File.extname(original)
      basename = File.basename(original, extname)
      "#{dirname}/#{basename}_#{version}#{extname}".sub(/^\.\//, '')
    end
  end
end
