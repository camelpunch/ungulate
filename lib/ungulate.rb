require 'rubygems'
require 'bundler/setup'

require 'hashie'
require 'ungulate/server'
require 'ungulate/job'
require 'ungulate/sqs_message_queue'
require 'ungulate/file_upload'
require 'ungulate/blob_processor'
require 'ungulate/rmagick_version_creator'
require 'ungulate/s3_storage'
require 'ungulate/http'

module Ungulate
  class Configuration < Hashie::Mash; end
  class MissingConfiguration < StandardError; end

  def self.configuration
    @config ||=
      begin
        config = Configuration.new

        # default creds to those in ENV
        config.access_key_id = ENV['AMAZON_ACCESS_KEY_ID']
        config.secret_access_key = ENV['AMAZON_SECRET_ACCESS_KEY']

        config.queue = lambda {
          SqsMessageQueue.new(
            configuration.queue_name,
            :access_key_id => configuration.access_key_id,
            :secret_access_key => configuration.secret_access_key,
            :server => configuration.queue_server
          )
        }

        config.http = lambda {
          Http.new
        }

        config.version_creator = lambda {
          RmagickVersionCreator.new(:http => configuration.http.call)
        }

        config.storage = lambda {
          S3Storage.new(
            :access_key_id => configuration.access_key_id,
            :secret_access_key => configuration.secret_access_key,
            :region => configuration.s3_region
          )
        }

        config.blob_processor = lambda {
          BlobProcessor.new(
            :version_creator => configuration.version_creator.call
          )
        }

        config.job_processor = lambda {
          Job.new(
            :blob_processor => configuration.blob_processor.call,
            :storage => configuration.storage.call,
            :http => configuration.http.call
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
  ActionView::Base.send :include, Ungulate::ViewHelpers
end
