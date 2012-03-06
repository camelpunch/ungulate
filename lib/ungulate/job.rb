require 'yaml'

module Ungulate
  class Job
    def initialize(options = {})
      @logger = options[:logger] || ::Logger.new($stdout)
      @blob_processor = options[:blob_processor]
      @storage = options[:storage]
      @http = options[:http]
    end

    def process(encoded_job)
      @attributes = YAML.load(encoded_job)
      bucket = @storage.bucket(@attributes[:bucket], :listener => self)
      versions = @attributes[:versions]
      blob = bucket.retrieve(@attributes[:key])

      @blob_processor.process(
        :blob => blob, :versions => versions,
        :bucket => bucket, :original_key => @attributes[:key]
      )
    end

    def storage_complete(version)
      stored_versions << version

      if @attributes[:notification_url] && stored_versions == versions_to_process
        @http.put @attributes[:notification_url]
      end
    end

    private

    def stored_versions
      @stored_versions ||= Set.new
    end

    def versions_to_process
      @versions_to_process ||= Set.new @attributes[:versions].keys
    end
  end
end
