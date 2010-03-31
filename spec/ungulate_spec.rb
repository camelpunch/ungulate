require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Ungulate do
  describe "run" do
    before do
      ENV['AMAZON_ACCESS_KEY_ID'] = 'test-secret'
      ENV['AMAZON_SECRET_ACCESS_KEY'] = 'test-key-id'
      ENV['QUEUE'] = 'test-queue'

      @instruction = '{
        bucket: test-bucket, 
        key: test-key, 
        versions: {
          thumb: { width: 100, height: 200 },
          large: { width: 200, height: 300 }
        }
      }'

      @q = mock('Queue')
      @q.stub!(:pop).and_return(@instruction)
      @sqs = mock('SqsGen2')
      @sqs.stub!(:queue).with('test-queue').and_return(@q)
      RightAws::SqsGen2.stub!(:new).with('test-key-id', 'test-secret').and_return(@sqs)
    end

    context "with thumbnail and large versions" do
      it "should send a thumbnail to S3"
      it "should sened a large version to S3"
    end
  end
end
