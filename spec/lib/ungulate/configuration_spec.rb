require 'spec_helper'
require 'ungulate/configuration'

module Ungulate
  describe Configuration do
    it "allows setting and retrieval of configuration items" do
      subject.somekey = 'somevalue'
      subject.somekey.should == 'somevalue'
    end
  end
end
