require 'spec_helper'
require 'ungulate/file_upload'
require 'active_support/core_ext/numeric/time'
require 'active_support/values/time_zone'

describe Ungulate::FileUpload do
  subject(:file_upload) { Ungulate::FileUpload.new }

  let(:california_offset) { -(8 / 24.0) }
  let(:utc_offset) { 0 }
  let(:expiration) { DateTime.new(2011, 11, 2, 12, 0, 0, california_offset) }
  let(:expiration_utc) { DateTime.new(2011, 11, 2, 20, 0, 0, utc_offset) }
  let(:bucket_url) { "http://images.bob.com/" }
  let(:key) { "new-file" }
  let(:access_key_id) { "asdf" }
  let(:secret_access_key) { 'uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o' }
  let(:acl) { 'public-read' }
  let(:success_action_redirect) { "http://johnsmith.s3.amazonaws.com/successful_upload.html" }
  let(:input_policy) do
    {
      "expiration" => expiration,
      "conditions" => [
        {"bucket" => "johnsmith" },
        ["starts-with", "$key", "user/eric/"],
        {"acl" => acl },
        {"success_action_redirect" => success_action_redirect },
        ["starts-with", "$Content-Type", "image/"],
        {"x-amz-meta-uuid" => "14365123651274"},
        ["starts-with", "$x-amz-meta-tag", ""]
      ]
    }
  end

  let(:policy_utc) do
    policy = input_policy.clone
    policy['expiration'] = expiration_utc
    policy
  end

  before do
    Ungulate.configuration.stub(:access_key_id).and_return(access_key_id)
    Ungulate.configuration.stub(:secret_access_key).and_return(secret_access_key)
    Ungulate.configuration.stub(:queue).and_return lambda { queue }
  end

  it "allows reading of the configured Amazon Access Key ID" do
    file_upload.should have_reader_for :access_key_id
  end

  context "when attributes set in constructor" do
    subject(:file_upload) do
      Ungulate::FileUpload.new(
        :bucket_url => bucket_url,
        :policy => input_policy,
        :key => key
      )
    end

    it { should have_reader_for :acl }
    it { should have_reader_for :bucket_url }
    it { should have_reader_for :key }
    it { should have_reader_for :success_action_redirect }

    it "converts expiration to UTC" do
      decoded_policy = ActiveSupport::JSON.decode(Base64.decode64(file_upload.policy))
      decoded_policy['expiration'].should == expiration_utc.to_s
    end

    it "converts mixed-hash-and-array input conditions to a nested array" do
      file_upload.conditions.should == [
        ['bucket', 'johnsmith'],
        ['starts-with', '$key', 'user/eric/'],
        ['acl', 'public-read'],
        ['success_action_redirect', 'http://johnsmith.s3.amazonaws.com/successful_upload.html'],
        ['starts-with', '$Content-Type', 'image/'],
        ["x-amz-meta-uuid", "14365123651274"],
        ["starts-with", "$x-amz-meta-tag", ""]
      ]
    end

    specify "policy is base64-encoded JSON of UTC-converted input policy, with no newlines" do
      json = "{ some: 'json' }"
      ActiveSupport::JSON.should_receive(:encode).with(policy_utc).and_return(json)
      Base64.should_receive(:encode64).with(json).and_return("ENCODED\nLINE\nLINE")

      file_upload.policy.should == "ENCODEDLINELINE"
    end
  end

  describe "enqueuing a job for processing" do
    let(:queue) { double 'queue' }
    let(:job) { { :large => [ :resize_to_fit, 654, 123 ] } }

    it "sends the YAML-encoded job to the configured queue" do
      queue.should_receive(:push).with(job.to_yaml)
      Ungulate::FileUpload.enqueue(job)
    end
  end

  describe "signature" do
    let(:sha1) { stub 'SHA1' }

    before do
      file_upload.stub(:policy).and_return(:policy)
      OpenSSL::Digest::Digest.stub(:new).with('sha1').and_return(sha1)
      OpenSSL::HMAC.stub(:digest).with(sha1, secret_access_key, :policy).and_return(:digest)
      Base64.stub(:encode64).with(:digest).and_return("str\nipme\n")
    end

    it "returns the stripped base64 encoded digest" do
      file_upload.signature.should == "stripme"
    end
  end
end
