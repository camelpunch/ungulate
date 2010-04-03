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
      @bucket = mock('Bucket')
      @sqs = mock('SqsGen2')
      @s3 = mock('S3')
      @q = mock('Queue')
    end

    describe :sqs do
      before do
        RightAws::SqsGen2.stub(:new).with('test-key-id', 'test-secret').and_return(@sqs)
      end

      it "should return a SqsGen2 instance using environment variables" do
        Job.sqs.should == @sqs
      end
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
        @q.stub(:pop).and_return(@message)

        @sqs.stub(:queue).with('test-queue').and_return(@q)
        Job.stub(:sqs).and_return(@sqs)

        RightAws::S3.stub(:new).with('test-key-id', 'test-secret').and_return(@s3)
        @s3.stub(:bucket).with('test-bucket').and_return(@bucket)
      end

      subject { Job.pop('test-queue') }

      it { should be_a(Job) }
      its(:bucket) { should == @bucket }
      its(:key) { should == @job_attributes[:key] }
      its(:queue) { should == @q }
      its(:versions) { should == @versions }
    end

    describe :s3 do
      before do
        RightAws::S3.stub(:new).with('test-key-id', 'test-secret').and_return(@s3)
      end

      it "should return a S3 instance using environment variables" do
        Job.s3.should == @s3
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

    describe :version_key do
      subject do
        job = Job.new
        job.stub(:key).and_return('path/to/some/file_name.png')
        job
      end

      it "should put the version before the extension" do
        subject.version_key(:extra_large).should == 'path/to/some/file_name_extra_large.png'
      end
    end
  end
end
