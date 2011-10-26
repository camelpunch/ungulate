require 'rubygems'
require 'right_aws'
require 'RMagick'
require 'mime/types'
require 'yaml'
require 'active_support/core_ext'
require 'curb'

module Ungulate
  class Job
    attr_accessor :bucket, :key, :notification_url, :queue, :versions

    @@blobs_from_urls = {}
    cattr_accessor :blobs_from_urls

    def self.s3
      @s3 ||=
        RightAws::S3.new(ENV['AMAZON_ACCESS_KEY_ID'],
                         ENV['AMAZON_SECRET_ACCESS_KEY'])
    end

    def self.sqs
      @sqs ||= 
        RightAws::SqsGen2.new(ENV['AMAZON_ACCESS_KEY_ID'],
                              ENV['AMAZON_SECRET_ACCESS_KEY'])
    end

    def initialize(options = {})
      @logger = options[:logger] || ::Logger.new($stdout)
      @image_processor = options[:image_processor]
      @storage = options[:storage]
      @http = options[:http]
      self.versions = []
    end

    def process(encoded_job = nil)
      if encoded_job
        @attributes = YAML.load(encoded_job)
        bucket = @storage.bucket(@attributes[:bucket])
        versions = @attributes[:versions]
        blob = bucket.retrieve(@attributes[:key])

        @image_processor.process(
          :blob => blob, :versions => versions,
          :bucket => bucket, :listener => self
        )
      else
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

    public

    def attributes=(options)
      self.bucket = Job.s3.bucket(options[:bucket])
      self.key = options[:key]
      self.notification_url = options[:notification_url]
      self.versions = options[:versions]
    end

    def processed_versions
      @processed_versions ||=
        versions.map do |name, instruction|
          [name, processed_image(source_image, instruction)]
        end
    end

    def blob_from_url(url)
      Job.blobs_from_urls[url] ||=
        begin
          @logger.info "Grabbing blob from URL #{url}"
          Curl::Easy.http_get(url).body_str
        end
    end

    def magick_image_from_url(url)
      Magick::Image.from_blob(blob_from_url(url)).first
    end

    def instruction_args(args)
      args.map do |arg|
        if arg.is_a?(Symbol)
          "Magick::#{arg.to_s.classify}".constantize
        elsif arg.respond_to?(:match) && arg.match(/^http/)
          magick_image_from_url(arg)
        else
          arg
        end
      end
    end

    def image_from_instruction(original, instruction)
      method, *args = instruction
      send_args = instruction_args(args)

      @logger.info "Performing #{method} with #{args.join(', ')}"
      original.send(method, *send_args).tap do |new_image|
        original.destroy!
        send_args.select {|arg| arg.is_a?(Magick::Image)}.each(&:destroy!)
      end
    end

    def image_from_instruction_chain(original, chain)
      if chain.one?
        image_from_instruction(original, chain.first)
      else
        image_from_instruction_chain(
          image_from_instruction(original, chain.shift),
          chain
        )
      end
    end

    def processed_image(original, instruction)
      if instruction.first.respond_to?(:entries)
        image_from_instruction_chain(original, instruction)
      else
        image_from_instruction(original, instruction)
      end
    end

    def source_image
      Magick::Image.from_blob(source).first
    end

    def source
      if @source
        @source
      else
        @logger.info "Grabbing source image #{key}"
        @source = bucket.get key
      end
    end

    def send_notification
      return false if notification_url.blank?

      @logger.info "Sending notification to #{notification_url}"
      Curl::Easy.http_put(notification_url, '')
    end

    def version_key(version)
      dirname = File.dirname(key)
      extname = File.extname(key)
      basename = File.basename(key, extname)
      "#{dirname}/#{basename}_#{version}#{extname}".sub(/^\.\//, '')
    end
  end
end
