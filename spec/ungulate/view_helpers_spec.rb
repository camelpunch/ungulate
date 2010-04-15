require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'ungulate/view_helpers'

class Includer
  include ViewHelpers
  attr_accessor :output_buffer

  def concat(string)
    self.output_buffer << string
  end
end

module Ungulate
  describe ViewHelpers do
    describe "ungulate_upload_form_for" do
      def helper
        @helper ||= Includer.new
      end

      before do
        @file_upload = mock('Ungulate::FileUpload',
                            :access_key_id => 'awsaccesskeyid',
                            :acl => 'private',
                            :bucket_url => 'http://static.test.s3.amazonaws.com/',
                            :key => 'some/key',
                            :policy => 'thepolicy',
                            :signature => 'thesignature',
                            :success_action_redirect => '/some/place')
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
  end
end
