require 'active_support'
class Ungulate::FileUpload
  attr_accessor(
    :bucket_url,
    :key,
    :policy
  )

  cattr_accessor(
    :access_key_id,
    :queue_name,
    :secret_access_key
  )

  def initialize(params)
    self.bucket_url = params[:bucket_url]
    self.key = params[:key]
    self.policy = params[:policy]
  end

  def acl
    condition 'acl'
  end

  def condition(key)
    conditions.find {|condition| condition.first == key}.second
  end

  def conditions
    @conditions ||=
      @policy_ruby['conditions'].map {|condition| condition.to_a.flatten}
  end

  def enqueue(job_description)
    queue.send_message(job_description.to_yaml)
  end

  def policy=(policy)
    @policy_ruby = policy
    @policy_ruby['expiration'].utc
    policy_json = ActiveSupport::JSON.encode(@policy_ruby)
    @policy = Base64.encode64(policy_json).gsub("\n", '')
  end

  def queue
    sqs = RightAws::SqsGen2.new(Ungulate::FileUpload.access_key_id,
                                Ungulate::FileUpload.secret_access_key)
    sqs.queue(Ungulate::FileUpload.queue_name)
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
