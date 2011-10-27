require 'spec_helper'
require 'ungulate'

describe Ungulate do
  describe "configuration" do
    it "returns the same object every time" do
      Ungulate.configuration.should equal(Ungulate.configuration)
    end

    it "yields the current configuration" do
      Ungulate.configure do |config|
        config.should == Ungulate::configuration
      end
    end

    it "allows setting and retrieving values" do
      Ungulate.configure do |config|
        config.bob = 'tree'
      end

      Ungulate.configuration.bob.should == 'tree'
    end
  end
end
