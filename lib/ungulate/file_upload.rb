require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/json'

module Ungulate
  class FileUpload
    attr_accessor :bucket_url, :key

    class << self
      def config
        Ungulate.configuration
      end

      def queue
        @queue ||= config.queue.call
      end

      def enqueue(job_description)
        queue.push(job_description.to_yaml)
      end
    end

    def initialize(options = {})
      self.bucket_url = options[:bucket_url]
      self.key = options[:key]

      if options[:policy]
        self.policy = options[:policy]
      end
    end

    def config
      self.class.config
    end

    def access_key_id
      config.access_key_id
    end

    def acl
      condition 'acl'
    end

    def condition(key)
      found_key, found_value = conditions.find {|condition| condition.first == key}
      found_value if found_value
    end

    def conditions
      @conditions ||=
        @policy_ruby['conditions'].map {|condition| condition.to_a.flatten}
    end

    def policy
      Base64.encode64(
        ActiveSupport::JSON.encode(@policy_ruby)
      ).gsub("\n", '')
    end

    def policy=(new_policy)
      new_policy['expiration'] = new_policy['expiration'].utc
      @policy_ruby = new_policy
      policy
    end

    def success_action_redirect
      condition 'success_action_redirect'
    end

    def signature
      Base64.encode64(
        OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'),
                             config.secret_access_key,
                             policy)
      ).gsub("\n", '')
    end
  end
end
