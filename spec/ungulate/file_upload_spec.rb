require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'ungulate/file_upload'

module Ungulate
  describe FileUpload do
    before do
      @expiration = 10.hours.from_now
      @bucket_url = "http://images.bob.com/"
      @key = "new-file"

      @policy = { 
        "expiration" => @expiration,
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

      @access_key_id = "asdf"
      @secret_access_key = 'uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o'
      FileUpload.access_key_id = @access_key_id
      FileUpload.secret_access_key = @secret_access_key
      FileUpload.queue_name = 'some-queue-name'
    end

    subject do
      FileUpload.new(
        :bucket_url => @bucket_url,
        :policy => @policy,
        :key => @key
      )
    end

    its(:acl) { should == 'public-read' }
    its(:bucket_url) { should == @bucket_url }
    its(:conditions) { should == [
      ['bucket', 'johnsmith'], 
      ['starts-with', '$key', 'user/eric/'],
      ['acl', 'public-read'],
      ['success_action_redirect', 'http://johnsmith.s3.amazonaws.com/successful_upload.html'],
      ['starts-with', '$Content-Type', 'image/'],
      ["x-amz-meta-uuid", "14365123651274"],
      ["starts-with", "$x-amz-meta-tag", ""]
    ] }
    its(:access_key_id) { should == @access_key_id }
    its(:key) { should == @key }
    its(:queue_name) { should == 'some-queue-name' }
    its(:success_action_redirect) { should == 'http://johnsmith.s3.amazonaws.com/successful_upload.html' }

    describe "condition" do
      before do
        subject.stub(:conditions).
          and_return([ ['colour', 'blue'], ['predicate', 'subject', 'object'] ])
      end

      it "should return the value of a tuple" do
        subject.condition('colour').should == 'blue'
      end
    end

    describe "conditions" do
      it "should memoize" do
        subject.instance_variable_set('@conditions', :cache)
        subject.conditions.should == :cache
      end

      it "should convert mixed hash and array policy to nested arrays" do
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
      before do
        @q = mock('queue')
        Ungulate::FileUpload.stub(:queue).and_return(@q)
        @job_hash = mock('Hash', :to_yaml => :some_yaml)
      end

      it "should queue the yamlised version of the passed job hash" do
        @q.should_receive(:send_message).with(:some_yaml)
        Ungulate::FileUpload.enqueue(@job_hash)
      end
    end

    describe "policy=" do
      it "should store the ruby version for later use" do
        subject.policy = @policy
        subject.instance_variable_get('@policy_ruby').should_not be_blank
      end

      it "should store the base64 encoded JSON" do
        subject # load subject without stubs

        ActiveSupport::JSON.stub(:encode).with(@policy).and_return(:some_json)
        Base64.stub(:encode64).with(:some_json).and_return("ENCODED\nLINE\nLINE")
        subject.policy = @policy
        subject.policy.should == "ENCODEDLINELINE"
      end

      it "should ensure the expiration is utc" do
        @expiration.should_receive(:utc).at_least(:once)
        subject.policy = @policy
      end
    end

    describe "queue" do
      before do
        sqs = mock('sqs')
        FileUpload.queue_name = 'somequeuename'
        FileUpload.access_key_id = 'someaccesskey'
        FileUpload.secret_access_key = 'somesecret'
        RightAws::SqsGen2.stub(:new).with('someaccesskey', 'somesecret').
          and_return(sqs)
        sqs.stub(:queue).with('somequeuename').and_return(:queue_instance)
      end

      it "should return a queue instance" do
        Ungulate::FileUpload.queue.should == :queue_instance
      end
    end

    describe "signature" do
      before do
        subject.stub(:policy).and_return(:policy)
        @sha1 = mock('SHA1')
        OpenSSL::Digest::Digest.stub(:new).with('sha1').and_return(@sha1)
        OpenSSL::HMAC.stub(:digest).with(@sha1, @secret_access_key, :policy).and_return(:digest)
        Base64.stub(:encode64).with(:digest).and_return("str\nipme\n")
      end

      it "should return the stripped base64 encoded digest" do
        subject.signature.should == "stripme"
      end
    end
  end
end
