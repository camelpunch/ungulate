require 'rubygems'
require 'right_aws'
module Ungulate
  class Runner
    def run
      job = Job.pop
    end

    def pop_job
    end
  end

  class Job
    attr_accessor :bucket, :key

    def self.pop
      job = new
      message = queue.pop
      job_attributes = YAML.load message
      job.bucket = job_attributes[:bucket]
      job.key = job_attributes[:key]

      job
    end

    def self.queue
      @queue ||= RightAws::SqsGen2.new(ENV['AMAZON_ACCESS_KEY_ID'],
                                       ENV['AMAZON_SECRET_ACCESS_KEY']).
                                       queue(ENV['QUEUE'])
    end
  end
end
