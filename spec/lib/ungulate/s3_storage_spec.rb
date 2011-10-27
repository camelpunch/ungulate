require 'spec_helper'
require 'ungulate/s3_storage'

# integration test
module Ungulate
  describe S3Storage do
    def new_storage
      S3Storage.new(
        :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
      )
    end

    subject { new_storage }

    it "can store and retrieve blobs with keys" do
      bucket = subject.bucket('ungulate-test')
      bucket.clear
      bucket.store('somekey', 'somedata')
      bucket.retrieve('somekey').should == 'somedata'

      bucket.store('someotherkey', 'someotherdata')
      bucket.retrieve('someotherkey').should == 'someotherdata'
    end

    it "persists data across instances" do
      bucket = subject.bucket('ungulate-test')
      bucket.clear
      bucket.store('somekey', 'somedata')

      new_storage.bucket('ungulate-test').
        retrieve('somekey').should == 'somedata'
    end

    it "stores publicly accessible items" do
      bucket = subject.bucket('ungulate-test')
      bucket.clear
      bucket.store('somekey', 'somedata')

      Curl::Easy.http_get("ungulate-test.s3.amazonaws.com/somekey").body_str.
        should == 'somedata'
    end

    context "when listener set" do
      it "notifies the listener when it's done" do
        listener = double 'listener'
        bucket = subject.bucket('ungulate-test', :listener => listener)

        listener.should_receive(:storage_complete).with(:large)
        bucket.store('large', 'largedata', :version => :large)
      end

      context "but no version passed" do
        it "does not notify the listener" do
          listener = double 'listener'
          bucket = subject.bucket('ungulate-test', :listener => listener)

          listener.should_not_receive(:storage_complete)
          bucket.store('large', 'largedata')
        end
      end
    end
  end
end
