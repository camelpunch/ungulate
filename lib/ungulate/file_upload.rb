require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/json'
module Ungulate
  class FileUpload
    attr_reader(:acl, :bucket_url, :conditions,
                :key, :policy, :success_action_redirect)

    class << self
      def enqueue(job_description)
        queue.push(job_description.to_yaml)
      end

      protected

      def queue
        @queue ||= Ungulate.configuration.queue.call
      end
    end

    def initialize(options = {})
      @bucket_url = options[:bucket_url]
      @key = options[:key]
      @policy = options[:policy]

      if @policy
        @policy['expiration'] = @policy['expiration'].utc

        @conditions =
          @policy['conditions'].map {|condition| condition.to_a.flatten }

        @acl, @success_action_redirect =
          Hash[@conditions].values_at('acl', 'success_action_redirect')

        @policy =
          Base64.encode64(ActiveSupport::JSON.encode(@policy)).gsub("\n", '')
      end
    end

    def access_key_id
      config.access_key_id
    end

    def signature
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          config.secret_access_key,
          policy
      )).gsub("\n", '')
    end

    protected

    def config
      Ungulate.configuration
    end
  end
end
