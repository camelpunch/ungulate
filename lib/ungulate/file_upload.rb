require 'active_support'
require 'hmac/sha1'
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
    conditions.find {|condition| condition.first == 'acl'}.second
  end

  def conditions
    ActiveSupport::JSON.decode(@policy_json)['conditions'].
      map {|condition| condition.to_a.flatten}
  end

  def policy=(json)
    @policy_json = json
    @policy = Base64.encode64(json).gsub("\n", '')
  end

  def signature
    sha1 = HMAC::SHA1.new(secret_access_key)
    sha1 << policy
    Base64.encode64(sha1.digest).strip
  end
end
