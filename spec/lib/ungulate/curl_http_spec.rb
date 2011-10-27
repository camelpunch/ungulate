require 'spec_helper'
require 'ungulate/curl_http'

module Ungulate
  describe CurlHttp do
    subject do
      CurlHttp.new(:logger => ::Logger.new(nil))
    end

    it "can return the body of a resource from https" do
      subject.get_body('https://dmxno528jhfy0.cloudfront.net/superhug-watermark.png').
        should == fixture('watermark.png')
    end

    it "can PUT to a HTTP URL" do
      response = subject.put('https://dmxno528jhfy0.cloudfront.net/superhug-watermark.png')
      response.code.should == 403
    end
  end
end
