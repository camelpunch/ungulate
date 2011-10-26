require 'rubygems'
require 'ungulate/server'
require 'ungulate/job'
require 'ungulate/sqs_message_queue'
require 'ungulate/rmagick_image_processor'
require 'ungulate/s3_storage'
require 'ungulate/curl_http'

module Ungulate
  def self.configuration
  end

  def self.configure
  end
end

if defined? ActionView::Base
  require 'ungulate/view_helpers'
  ActionView::Base.send :include, ViewHelpers
end
