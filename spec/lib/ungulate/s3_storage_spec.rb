require 'spec_helper'
require File.expand_path('../../../config/ungulate', File.dirname(__FILE__))
require 'ungulate/s3_storage'
require 'ostruct'

describe Ungulate::S3Storage, :integration => true do
  def new_storage
    Ungulate::S3Storage.new(
      :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'],
      :region => 'eu-west-1'
    )
  end

  def config
    Ungulate.configuration
  end

  subject { new_storage }

  it "warns when in the wrong region" do
    old_stderr = $stderr
    text = OpenStruct.new :write => nil
    $stderr = text
    storage = Ungulate::S3Storage.new(
      :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
    )
    storage.bucket(config.test_bucket)
    text.should be_present
    $stderr = old_stderr
  end

  it "can store and retrieve blobs with keys" do
    bucket = subject.bucket(config.test_bucket)
    bucket.delete('somekey')
    bucket.store('somekey', 'somedata')
    bucket.retrieve('somekey').should == 'somedata'

    bucket.store('someotherkey', 'someotherdata')
    bucket.retrieve('someotherkey').should == 'someotherdata'
  end

  it "persists data across instances" do
    bucket = subject.bucket(config.test_bucket)
    bucket.delete('somekey')
    bucket.store('somekey', 'somedata')

    new_storage.bucket('ungulate-test').
      retrieve('somekey').should == 'somedata'
  end

  it "stores publicly accessible items with a long cache expiry" do
    key = 'somekey'
    bucket = subject.bucket(config.test_bucket)
    bucket.delete('somekey')
    bucket.store(key, 'somedata')

    response = Excon.get("http://#{config.test_bucket}.s3.amazonaws.com/#{key}")
    response.get_header('cache-control').should == 'max-age=2629743'
  end

  it "sets the correct content-type" do
    key = 'somekey.png'
    bucket = subject.bucket(config.test_bucket)
    bucket.delete('somekey.png')
    bucket.store(key, 'somedata', :content_type => 'image/png')
    response = Excon.get("http://ungulate-test.s3.amazonaws.com/#{key}")
    response.get_header('content-type').should == 'image/png'
  end

  context "when listener set" do
    it "notifies the listener when it's done" do
      listener = double 'listener'
      bucket = subject.bucket(config.test_bucket, :listener => listener)

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
