require 'rubygems'
require 'right_aws'
require 'RMagick'
require 'mime/types'
require 'yaml'

module Ungulate
  class Job
    attr_accessor :bucket, :key, :queue, :versions

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

    def self.pop(queue_name)
      job = new
      job.queue = sqs.queue queue_name
      message = job.queue.pop
      attributes = YAML.load message.to_s
      job.attributes = attributes if attributes
      job
    end

    def initialize
      @logger = Ungulate::Server.logger
      self.versions = []
    end

    def attributes=(options)
      self.bucket = Job.s3.bucket(options[:bucket])
      self.key = options[:key]
      self.versions = options[:versions]
    end

    def processed_versions
      @processed_versions ||=
        versions.map do |name, instruction|
          method, x, y = instruction
          image = Magick::Image.from_blob(source).first
          @logger.info "Performing #{method} with #{x}, #{y}"
          processed_image = image.send(method, x, y)
          image.destroy!
          [name, processed_image]
        end
    end

    def source
      if @source
        @source
      else
        @logger.info "Grabbing source image #{key}"
        @source = bucket.get key
      end
    end

    def process
      return false if processed_versions.empty?
      processed_versions.each do |version, image|
        version_key = version_key version
        @logger.info "Storing #{version} @ #{version_key}"
        bucket.put(version_key, 
                   image.to_blob, 
                   {},
                   'public-read',
                   {'Content-Type' => MIME::Types.type_for(image.format).to_s})
        image.destroy!
      end
    end

    def version_key(version)
      dirname = File.dirname(key)
      extname = File.extname(key)
      basename = File.basename(key, extname)
      "#{dirname}/#{basename}_#{version}#{extname}".sub(/^\.\//, '')
    end
  end
end
