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
    attr_accessor :bucket, :key

    def self.queue
      @queue ||= RightAws::SqsGen2.new(ENV['AMAZON_ACCESS_KEY_ID'],
                                       ENV['AMAZON_SECRET_ACCESS_KEY']).
                                       queue(ENV['QUEUE'])
    end

    def self.pop
      job = new
      message = queue.pop
      job_attributes = YAML.load message
      job.bucket = job_attributes[:bucket]
      job.key = job_attributes[:key]

      job
    end
  end
end
