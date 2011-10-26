require 'spec_helper'
require 'ungulate/view_helpers'
require 'active_support/core_ext'

class Rails2Includer
  include ViewHelpers
  attr_accessor :output_buffer

  def concat(string)
    self.output_buffer << string
  end
end

class Rails3Includer
  include ViewHelpers
end

module Ungulate
  describe ViewHelpers do
    describe "ungulate_upload_form_for" do
      before do
        @file_upload = mock('Ungulate::FileUpload',
                            :access_key_id => 'awsaccesskeyid',
                            :acl => 'private',
                            :bucket_url => 'http://static.test.s3.amazonaws.com/',
                            :key => 'some/key',
                            :policy => 'thepolicy',
                            :signature => 'thesignature',
                            :success_action_redirect => '/some/place')
      end

      context "rails 2.3.x style" do
        def helper
          @helper ||= Rails2Includer.new
        end

        before do
          helper.output_buffer = ''
          helper.ungulate_upload_form_for(@file_upload) do
            helper.concat('text in the middle')
          end
        end

        it "should have a complete form" do
          helper.output_buffer.should == <<-HTML
<form action="http://static.test.s3.amazonaws.com/" enctype="multipart/form-data" method="post">
<div>
<input name="key" type="hidden" value="some/key" />
<input name="AWSAccessKeyId" type="hidden" value="awsaccesskeyid" />
<input name="acl" type="hidden" value="private" />
<input name="policy" type="hidden" value="thepolicy" />
<input name="signature" type="hidden" value="thesignature" />
<input name="success_action_redirect" type="hidden" value="/some/place" />
text in the middle
</div>
</form>
          HTML
        end
      end

      context "rails 3 style" do
        def helper
          @helper ||= Rails3Includer.new
        end

        before do
          helper.stub(:respond_to?).with(:safe_concat).and_return(true)
          helper.stub(:capture)
          @safe_buffer = mock('SafeBuffer', :<< => nil, :safe_concat => nil)
          ActiveSupport::SafeBuffer.stub(:new).and_return(@safe_buffer)
        end

        it "should use a SafeBuffer" do
          @safe_buffer.should_receive(:safe_concat).ordered
          @safe_buffer.should_receive(:<<).ordered
          @safe_buffer.should_receive(:safe_concat).ordered
          helper.ungulate_upload_form_for(@file_upload) do
            helper.safe_concat('text in the middle')
          end
        end
      end
    end
  end
end
