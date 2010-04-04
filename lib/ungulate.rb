require 'rubygems'
require 'right_aws'
require 'RMagick'

module Ungulate
  def self.run(queue_name)
    Job.pop(queue_name).process
  end

  class Job
    attr_accessor :bucket, :key, :queue, :versions

    def self.s3
      RightAws::S3.new(ENV['AMAZON_ACCESS_KEY_ID'],
                       ENV['AMAZON_SECRET_ACCESS_KEY'])
    end

    def self.sqs
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
      self.versions = []
    end

    def attributes=(options)
      self.bucket = Job.s3.bucket(options[:bucket])
      self.key = options[:key]
      self.versions = options[:versions]
    end

    def processed_versions
      versions.map do |name, instruction|
        method, x, y = instruction
        image = Magick::Image.from_blob(source).first
        [name, image.send(method, x, y)]
      end
    end

    def source
      bucket.get key
    end

    def process
      return false if processed_versions.empty?
      processed_versions.each do |version, image|
        bucket.put(version_key(version), image.to_blob)
      end
    end

    def version_key(version)
      dirname = File.dirname(key)
      extname = File.extname(key)
      basename = File.basename(key, extname)
      "#{dirname}/#{basename}_#{version}#{extname}"
    end
  end
end
