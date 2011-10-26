require 'spec_helper'
require 'ungulate/file_upload'

module Ungulate
  describe FileUpload do
    let(:expiration) { 10.hours.from_now }
    let(:bucket_url) { "http://images.bob.com/" }
    let(:key) { "new-file" }
    let(:access_key_id) { "asdf" }
    let(:secret_access_key) { 'uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o' }
    let(:queue_name) { 'some-queue-name' }

    before do
      FileUpload.access_key_id = access_key_id
      FileUpload.secret_access_key = secret_access_key
      FileUpload.queue_name = queue_name
    end

    its(:access_key_id) { should == access_key_id }
    its(:queue_name) { should == queue_name }
    its(:secret_access_key) { should == secret_access_key }

    context "policy set directly" do
      let(:policy) do
        {
          "expiration" => expiration,
          "conditions" => [
            {"bucket" => "johnsmith" },
            ["starts-with", "$key", "user/eric/"],
            {"acl" => "public-read" },
            {"success_action_redirect" => "http://johnsmith.s3.amazonaws.com/successful_upload.html" },
            ["starts-with", "$Content-Type", "image/"],
            {"x-amz-meta-uuid" => "14365123651274"},
            ["starts-with", "$x-amz-meta-tag", ""]
          ]
        }
      end

      subject do
        FileUpload.new(
          :bucket_url => bucket_url,
          :policy => policy,
          :key => key
        )
      end

      its(:acl) { should == 'public-read' }
      its(:bucket_url) { should == bucket_url }
      its(:conditions) { should == [
        ['bucket', 'johnsmith'],
        ['starts-with', '$key', 'user/eric/'],
        ['acl', 'public-read'],
        ['success_action_redirect', 'http://johnsmith.s3.amazonaws.com/successful_upload.html'],
        ['starts-with', '$Content-Type', 'image/'],
        ["x-amz-meta-uuid", "14365123651274"],
        ["starts-with", "$x-amz-meta-tag", ""]
      ] }
      its(:key) { should == key }
      its(:success_action_redirect) { should == 'http://johnsmith.s3.amazonaws.com/successful_upload.html' }
    end

    describe "condition" do
      before do
        subject.stub(:conditions).
          and_return([ ['colour', 'blue'], ['predicate', 'subject', 'object'] ])
      end

      it "returns value of index 1 in a two-item array" do
        subject.condition('colour').should == 'blue'
      end

      it "copes with missing attribute" do
        subject.condition('bob').should be_nil
      end
    end

    describe "conditions" do
      it "memoizes" do
        subject.instance_variable_set('@conditions', :cache)
        subject.conditions.should == :cache
      end

      it "converts mixed hash and array policy to nested arrays" do
        subject.
          instance_variable_set('@policy_ruby',
                                {
                                  'conditions' => [
                                    {'colour' => 'blue'},
                                    ['predicate', 'subject', 'object']
                                  ]
                                })
        subject.conditions.should == [ ['colour', 'blue'], ['predicate', 'subject', 'object'] ]
      end
    end

    describe "enqueue" do
      let(:q) { stub 'queue' }
      let(:job_hash) { stub('Hash', :to_yaml => :some_yaml) }
      before { Ungulate::FileUpload.stub(:queue).and_return(q) }

      it "queues the yamlised version of the passed job hash" do
        q.should_receive(:send_message).with(:some_yaml)
        Ungulate::FileUpload.enqueue(job_hash)
      end
    end

    describe "policy" do
      it "returns base64 encoded JSON version of stored policy" do
        subject.instance_variable_set('@policy_ruby', :some_policy)
        ActiveSupport::JSON.stub(:encode).with(:some_policy).and_return(:json)
        Base64.stub(:encode64).with(:json).and_return("ENCODED\nLINE\nLINE")
        subject.policy.should == "ENCODEDLINELINE"
      end
    end

    describe "policy=" do
      let(:policy) do
        {
          "expiration" => expiration,
          "conditions" => [
            {"bucket" => "johnsmith" },
            ["starts-with", "$key", "user/eric/"],
            {"acl" => "public-read" },
            {"success_action_redirect" => "http://johnsmith.s3.amazonaws.com/successful_upload.html" },
            ["starts-with", "$Content-Type", "image/"],
            {"x-amz-meta-uuid" => "14365123651274"},
            ["starts-with", "$x-amz-meta-tag", ""]
          ]
        }
      end

      it "stores the ruby version for later use" do
        subject.policy = policy
        subject.instance_variable_get('@policy_ruby').should_not be_blank
      end

      it "ensures the expiration is utc" do
        utc_time = Time.now.utc

        expiration.stub(:utc).and_return(utc_time)
        Base64.stub(:encode64).and_return('')

        ActiveSupport::JSON.should_receive(:encode).
          with(hash_including('expiration' => utc_time)).
          any_number_of_times

        subject.policy = policy
      end

      it "returns the encoded policy" do
        subject.stub(:policy).and_return(:encoded_policy)
        subject.send(:policy=, policy).should == :encoded_policy
      end
    end

    describe "queue" do
      let(:sqs) do
        sqs = stub 'SQS'
        sqs.stub(:queue).with(queue_name).and_return(:queue_instance)
        sqs
      end

      subject { Ungulate::FileUpload.queue }

      before do
        RightAws::SqsGen2.stub(:new).
          with(access_key_id, secret_access_key).
          and_return(sqs)
      end

      it { should == :queue_instance }
    end

    describe "signature" do
      let(:sha1) { stub 'SHA1' }

      before do
        subject.stub(:policy).and_return(:policy)
        OpenSSL::Digest::Digest.stub(:new).with('sha1').and_return(sha1)
        OpenSSL::HMAC.stub(:digest).with(sha1, secret_access_key, :policy).and_return(:digest)
        Base64.stub(:encode64).with(:digest).and_return("str\nipme\n")
      end

      it "returns the stripped base64 encoded digest" do
        subject.signature.should == "stripme"
      end
    end
  end
end
