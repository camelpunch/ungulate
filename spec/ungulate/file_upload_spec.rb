require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'ungulate/file_upload'

module Ungulate
  describe FileUpload do
    subject do
      @bucket_url = "http://images.bob.com/"
      @access_key_id = "asdf"
      @key = "new-file"

      # examples taken from http://doc.s3.amazonaws.com/proposals/post.html#Access_Control
      @policy = '{ "expiration": "2007-12-01T12:00:00.000Z",
  "conditions": [
    {"bucket": "johnsmith" },
    ["starts-with", "$key", "user/eric/"],
    {"acl": "public-read" },
    {"redirect": "http://johnsmith.s3.amazonaws.com/successful_upload.html" },
    ["starts-with", "$Content-Type", "image/"],
    {"x-amz-meta-uuid": "14365123651274"},
    ["starts-with", "$x-amz-meta-tag", ""],
  ]
}
'
      @secret_access_key = 'uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o'

      FileUpload.new(
        :bucket_url => @bucket_url,
        :access_key_id => @access_key_id,
        :secret_access_key => @secret_access_key,
        :policy => @policy,
        :key => @key
      )
    end

    its(:acl) { should == 'private' }
    its(:bucket_url) { should == @bucket_url }
    its(:access_key_id) { should == @access_key_id }
    its(:key) { should == @key }
    its(:signature) { should == '2qCp0odXe7A9IYyUVqn0w2adtCA=' }
    its(:policy) { should == 'eyAiZXhwaXJhdGlvbiI6ICIyMDA3LTEyLTAxVDEyOjAwOjAwLjAwMFoiLAogICJjb25kaXRpb25zIjogWwogICAgeyJidWNrZXQiOiAiam9obnNtaXRoIiB9LAogICAgWyJzdGFydHMtd2l0aCIsICIka2V5IiwgInVzZXIvZXJpYy8iXSwKICAgIHsiYWNsIjogInB1YmxpYy1yZWFkIiB9LAogICAgeyJyZWRpcmVjdCI6ICJodHRwOi8vam9obnNtaXRoLnMzLmFtYXpvbmF3cy5jb20vc3VjY2Vzc2Z1bF91cGxvYWQuaHRtbCIgfSwKICAgIFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbnQtVHlwZSIsICJpbWFnZS8iXSwKICAgIHsieC1hbXotbWV0YS11dWlkIjogIjE0MzY1MTIzNjUxMjc0In0sCiAgICBbInN0YXJ0cy13aXRoIiwgIiR4LWFtei1tZXRhLXRhZyIsICIiXSwKICBdCn0K' }
  end
end
