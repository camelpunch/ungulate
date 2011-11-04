require 'rubygems'
require 'bundler/setup'

require 'hashie'
require 'ungulate/server'
require 'ungulate/job'
require 'ungulate/sqs_message_queue'
require 'ungulate/blob_processor'
require 'ungulate/rmagick_version_creator'
require 'ungulate/s3_storage'
require 'ungulate/curl_http'

module Ungulate
  class Configuration < Hashie::Mash; end
  class MissingConfiguration < StandardError; end

  def self.configuration
    @config ||=
      begin
        config = Configuration.new

        config.access_key_id = ENV['AMAZON_ACCESS_KEY_ID']
        config.secret_access_key = ENV['AMAZON_SECRET_ACCESS_KEY']

        amazon_credentials = {
          :access_key_id => config.access_key_id,
          :secret_access_key => config.secret_access_key
        }

        config.queue = lambda {
          SqsMessageQueue.new(
            config.queue_name,
            amazon_credentials.merge(:server => config.queue_server)
          )
        }

        config.http = lambda {
          CurlHttp.new
        }

        config.version_creator = lambda {
          RmagickVersionCreator.new(:http => config.http.call)
        }

        config.storage = lambda {
          S3Storage.new(amazon_credentials.merge(:region => config.s3_region))
        }

        config.blob_processor = lambda {
          BlobProcessor.new(
            :version_creator => config.version_creator.call
          )
        }

        config.job_processor = lambda {
          Job.new(
            :blob_processor => config.blob_processor.call,
            :storage => config.storage.call,
            :http => config.http.call
          )
        }

        config
      end
  end

  def self.configure(&block)
    yield configuration
  end
end

if defined? ActionView::Base
  require 'ungulate/view_helpers'
  ActionView::Base.send :include, ViewHelpers
end
