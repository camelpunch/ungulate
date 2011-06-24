require 'active_support/core_ext/class/attribute_accessors'
class Ungulate::FileUpload
  attr_accessor(
    :bucket_url,
    :key
  )

  cattr_accessor(
    :access_key_id,
    :queue_name,
    :secret_access_key
  )

  def self.enqueue(job_description)
    queue.send_message(job_description.to_yaml)
  end

  def self.queue
    sqs = RightAws::SqsGen2.new(access_key_id, secret_access_key)
    sqs.queue(queue_name)
  end

  def initialize(options = {})
    self.bucket_url = options[:bucket_url]
    self.key = options[:key]

    if options[:policy]
      self.policy = options[:policy]
    end
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
                           secret_access_key, 
                           policy)
    ).gsub("\n", '')
  end
end
