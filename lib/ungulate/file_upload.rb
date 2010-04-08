require 'active_support'
class Ungulate::FileUpload
  attr_accessor(
    :access_key_id,
    :bucket_url,
    :key,
    :policy,
    :secret_access_key
  )

  def initialize(params)
    self.access_key_id = params[:access_key_id]
    self.bucket_url = params[:bucket_url]
    self.key = params[:key]
    self.policy = params[:policy]
    self.secret_access_key = params[:secret_access_key]
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

  def policy=(policy)
    @policy_ruby = policy
    @policy_ruby['expiration'].utc
    policy_json = ActiveSupport::JSON.encode(@policy_ruby)
    @policy = Base64.encode64(policy_json).gsub("\n", '')
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
