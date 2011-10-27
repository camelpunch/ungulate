require 'spec_helper'
require 'ungulate/curl_http'

module Ungulate
  describe CurlHttp do
    it "can return the body of a resource from https" do
      http = CurlHttp.new
      http.get_body('https://dmxno528jhfy0.cloudfront.net/superhug-watermark.png').
        should == fixture('watermark.png')
    end
  end
end
