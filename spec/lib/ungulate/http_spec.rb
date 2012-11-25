require 'spec_helper'
require 'ungulate/http'

describe Ungulate::Http, :integration => true do
  subject(:http) { Ungulate::Http.new(:logger => ::Logger.new(nil)) }

  it "can return the body of a resource from https" do
    http.get_body('https://d1h33x9n430k4r.cloudfront.net/cute-sad-cat.jpg').
      should == fixture('watermark.png')
  end

  it "can PUT to a HTTP URL" do
    response = http.put('https://d1h33x9n430k4r.cloudfront.net/cute-sad-cat.jpg')
    response.code.should == 403
  end
end
