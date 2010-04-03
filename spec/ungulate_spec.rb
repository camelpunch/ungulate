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
      @bucket = mock('Bucket')
    end

    describe :pop do
      before do
        @versions = {
          :thumb => [ :resize_to_fit, 100, 200 ],
          :large => [ :resize_to_fit, 200, 300 ],
        }
        @job_attributes = {
          :bucket => 'test-bucket', 
          :key => 'test-key', 
          :versions => @versions
        }

        @message = mock('Message', :read => @job_attributes.to_yaml)
        @q = mock('Queue')
        @q.stub(:pop).and_return(@message)
        Job.stub(:queue).and_return(@q)

        @s3 = mock('S3')
        RightAws::S3.stub(:new).with('test-key-id', 'test-secret').and_return(@s3)
        @s3.stub(:bucket).with('test-bucket').and_return(@bucket)
      end

      subject { Job.pop }

      it { should be_a(Job) }
      its(:bucket) { should == @bucket }
      its(:key) { should == @job_attributes[:key] }
      its(:versions) { should == @versions }
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
      subject do
        job = Job.new
        versions = {
          :large => [ :resize_to_fit, 100, 200 ],
          :small => [ :resize_to_fill, 64, 64 ],
        }
        job.stub(:versions).and_return(versions)
        job.stub(:key).and_return('someimage.jpg')

        job.stub(:source).and_return(:data)
        @source_image = mock('Image')
        Magick::Image.stub(:from_blob).with(:data).and_return([@source_image])

        @source_image.stub(:resize_to_fit).with(100, 200).and_return(@large)
        @source_image.stub(:resize_to_fill).with(64, 64).and_return(@small)

        job.process
        job
      end

        #job.bucket.should_receive(:put).with('someimage_large.jpg', @large)

      its(:processed_versions) { should == { :large => @large, :small => @small } }
    end

    describe :store do
      subject do
        job = Job.new
        @big = mock('Image', :to_blob => 'bigdata')
        @little = mock('Image', :to_blob => 'littledata')
        job.stub(:processed_versions).and_return(:big => @big, :little => @little)
        job.stub(:bucket).and_return(@bucket)
        job.stub(:version_key).with(:big).and_return('path/to/someimage_big.jpg')
        job.stub(:version_key).with(:little).and_return('path/to/someimage_little.jpg')
        job
      end

      after { subject.store }

      it "should send each processed version to S3" do
        @bucket.should_receive(:put).with('path/to/someimage_big.jpg', 'bigdata')
        @bucket.should_receive(:put).with('path/to/someimage_little.jpg', 'littledata')
      end
    end
  end
end
