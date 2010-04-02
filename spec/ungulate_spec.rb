require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Ungulate
  describe Runner do
    describe "run" do
      before do
        @versions = {
          :thumb => [ :resize_to_fit, 100, 200 ],
          :large => [ :resize_to_fit, 200, 300 ],
        }

        @data = mock('Data')
        @job = mock('Ungulate::Job', 
                    :versions => @versions,
                    :source => @data,
                    :process => nil,
                    :store => nil)

        Ungulate::Job.stub(:pop).and_return(@job)

        @image = mock('RMagick::Image')

        @datum = mock('Datum')
        @data_array = [@datum]

        Magick::Image.stub(:from_blob).with(@data).and_return(@data_array)
      end

      after { subject.run }

      it "should pop a job" do
        Ungulate::Job.should_receive(:pop)
      end

      it "should process the job and store the results" do
        @job.should_receive(:process).ordered
        @job.should_receive(:store).ordered
      end
    end
  end

  describe Job do
    before do
      ENV['AMAZON_ACCESS_KEY_ID'] = 'test-key-id'
      ENV['AMAZON_SECRET_ACCESS_KEY'] = 'test-secret'
      ENV['QUEUE'] = 'test-queue'
    end

    describe :pop do
      before do
        @job_attributes = {
          :bucket => 'test-bucket', 
          :key => 'test-key', 
          :versions => {
            :thumb => [ :resize_to_fit, 100, 200 ],
            :large => [ :resize_to_fit, 200, 300 ],
          }
        }

        @message = mock('Message', :read => @job_attributes.to_yaml)
        @q = mock('Queue')
        @q.stub(:pop).and_return(@message)
        Job.stub(:queue).and_return(@q)

        @s3 = mock('S3')
        RightAws::S3.stub(:new).with('test-key-id', 'test-secret').and_return(@s3)
        @bucket = mock('Bucket')
        @s3.stub(:bucket).with('test-bucket').and_return(@bucket)
      end

      subject { Job.pop }

      it { should be_a(Job) }
      its(:bucket) { should == @bucket }
      its(:key) { should == @job_attributes[:key] }
    end

    describe :queue do
      before do
        @q = mock('Queue')
        @sqs = mock('Sqs')
        @sqs.stub(:queue).with('test-queue').and_return(@q)

        RightAws::SqsGen2.stub(:new).with('test-key-id', 'test-secret').and_return(@sqs)
      end

      subject { Job.queue }

      it { should == @q }

      describe "when already called" do
        before do
          Job.instance_variable_set('@queue', @q)
        end

        it "should not instantiate afresh" do
          RightAws::SqsGen2.should_not_receive(:new)
          Job.queue
        end
      end
    end

    describe :source do
      subject do
        job = Job.new
        job.stub(:key).and_return('test-key')
        job.stub_chain(:bucket, :get).with('test-key').and_return(:data)
        job
      end

      it "should return data from S3" do
        subject.source.should == :data
      end
    end

    describe :process do
      it "should load the source into an image"
      it "should loop through versions, storing new versions in memory" 
    end

    describe :store do
      it "should send each processed version to S3"
    end
  end
end
