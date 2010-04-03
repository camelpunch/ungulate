require 'rubygems'
require 'right_aws'
require 'RMagick'

module Ungulate
  class Runner
    def run
      job = Job.pop
      job.process
      job.store
    end
  end

  class Job
    attr_accessor :bucket, :key, :processed_versions, :queue, :versions

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

      job_attributes = YAML.load message

      job.bucket = s3.bucket(job_attributes[:bucket])
      job.key = job_attributes[:key]
      job.versions = job_attributes[:versions]

      job
    end

    def process
      self.processed_versions = {}

      versions.each_pair do |name, instruction|
        method, x, y = instruction

        image = Magick::Image.from_blob(source).first
        self.processed_versions[name] = image.send(method, x, y)
      end
    end

    def source
      bucket.get key
    end

    def store
      processed_versions.each_pair do |version, image|
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
