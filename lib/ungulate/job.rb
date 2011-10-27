require 'rubygems'
require 'RMagick'
require 'mime/types'
require 'yaml'

module Ungulate
  class Job
    def initialize(options = {})
      @logger = options[:logger] || ::Logger.new($stdout)
      @blob_processor = options[:blob_processor]
      @storage = options[:storage]
      @http = options[:http]
    end

    def process(encoded_job = nil)
      if encoded_job
        @attributes = YAML.load(encoded_job)
        bucket = @storage.bucket(@attributes[:bucket])
        versions = @attributes[:versions]
        blob = bucket.retrieve(@attributes[:key])

        @blob_processor.process(
          :blob => blob, :versions => versions,
          :bucket => bucket, :original_key => @attributes[:key],
          :listener => self
        )
      else
=begin
        return false if processed_versions.empty?

        processed_versions.each do |version, image|
          version_key = version_key version
          @logger.info "Storing #{version} @ #{version_key}"
          bucket.put(
            version_key, 
            image.to_blob, 
            {},
            'public-read',
            {
            'Content-Type' => MIME::Types.type_for(image.format).to_s,
            # expire in about one month: refactor to grab from job description
            'Cache-Control' => 'max-age=2629743',
          }
          )
          image.destroy!
        end

        send_notification

        true
=end
      end
    end

    def storage_complete(version)
      stored_versions << version

      if @attributes[:notification_url] && stored_versions == versions_to_process
        @http.put @attributes[:notification_url]
      end
    end

    protected

    def stored_versions
      @stored_versions ||= Set.new
    end

    def versions_to_process
      @versions_to_process ||= Set.new @attributes[:versions].keys
    end
  end
end
