require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Ungulate
  describe "run" do
    before do
      @versions = {
        :thumb => [ :resize_to_fit, 100, 200 ],
        :large => [ :resize_to_fit, 200, 300 ],
      }

      @data = mock('Data')
      @job = mock('Job', 
                  :versions => @versions,
                  :source => @data,
                  :process => nil,
                  :store => nil)

      Job.stub(:pop).and_return(@job)

      @image = mock('RMagick::Image')

      @datum = mock('Datum')
      @data_array = [@datum]

      Magick::Image.stub(:from_blob).with(@data).and_return(@data_array)
    end

    after { Ungulate.run('queuename') }

    it "should pop a job from the provided queue" do
      Job.should_receive(:pop).with('queuename')
    end

    it "should process the job" do
      @job.should_receive(:process)
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
      @versions = {
        :thumb => [ :resize_to_fit, 100, 200 ],
        :large => [ :resize_to_fit, 200, 300 ],
      }
    end

    its(:versions) { should == [] }

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
        @job_attributes = {
          :bucket => 'test-bucket', 
          :key => 'test-key', 
          :versions => @versions
        }

        @sqs.stub(:queue).with('test-queue').and_return(@q)

        message = mock('Message', :to_s => :message_data)

        @q.stub(:pop).and_return(message)
        YAML.stub(:load).with(:message_data).and_return(:attributes)

        Job.stub(:sqs).and_return(@sqs)
        Job.stub(:s3).and_return(@s3)

        @job = mock('Job', :attributes= => nil, :queue= => nil, :queue => @q)
        Job.stub(:new).and_return(@job)
      end

      after { Job.pop('test-queue') }

      it "should set attributes" do
        @job.should_receive(:attributes=).with(:attributes)
      end

      it "should set the queue" do
        @job.should_receive(:queue=).with(@q)
      end

      context "when YAML.load returns false" do
        before do
          YAML.stub(:load).with(:message_data).and_return(false)
        end

        it "should not set attributes" do
          @job.should_not_receive(:attributes=)
        end
      end
    end

    describe :s3 do
      before do
        RightAws::S3.stub(:new).with('test-key-id', 'test-secret').and_return(@s3)
      end

      it "should return a S3 instance using environment variables" do
        Job.s3.should == @s3
      end
    end

    describe :attributes= do
      subject do
        Job.stub_chain(:s3, :bucket).with('hello').and_return(@bucket)

        job = Job.new
        job.attributes = { 
          :bucket => 'hello', 
          :key => 'path/to/filename.gif', 
          :versions => @versions
        }
        job
      end

      its(:bucket) { should == @bucket }
      its(:key) { should == 'path/to/filename.gif' }
      its(:versions) { should == @versions }
    end

    describe :source do
      subject do
        job = Job.new
        job.stub(:key).and_return('test-key')
        job.stub_chain(:bucket, :get).with('test-key').and_return(:s3_data)
        job.source
      end

      it { should == :s3_data }
    end

    describe :processed_versions do
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

        @source_image.stub(:resize_to_fit).with(100, 200).and_return(:large_image)
        @source_image.stub(:resize_to_fill).with(64, 64).and_return(:small_image)

        job.processed_versions
      end

      it { should include([:large, :large_image]) }
      it { should include([:small, :small_image]) }
    end

    describe :process do
      subject do
        job = Job.new
        @big = mock('Image', :to_blob => 'bigdata')
        @little = mock('Image', :to_blob => 'littledata')
        job.stub(:processed_versions).and_return([[:big, @big], [:little, @little]])
        job.stub(:bucket).and_return(@bucket)
        job.stub(:version_key).with(:big).and_return('path/to/someimage_big.jpg')
        job.stub(:version_key).with(:little).and_return('path/to/someimage_little.jpg')
        job
      end

      after { subject.process }

      it "should send each processed version to S3" do
        @bucket.should_receive(:put).with('path/to/someimage_big.jpg', 
                                          'bigdata',
                                          {},
                                          'public-read')
        @bucket.should_receive(:put).with('path/to/someimage_little.jpg', 
                                          'littledata',
                                          {},
                                          'public-read')
      end

      context "empty array" do
        before do
          subject.stub(:processed_versions).and_return([])
        end

        it "should not break" do
        end
      end
    end

    describe :version_key do
      subject do
        job = Job.new
        job.stub(:key).and_return('path/to/some/file_name.png')
        job.version_key(:extra_large)
      end

      it { should == 'path/to/some/file_name_extra_large.png' }

      context "no leading path" do
        subject do
          job = Job.new
          job.stub(:key).and_return('file_name.png')
          job.version_key(:extra_large)
        end

        it { should == 'file_name_extra_large.png' }
      end
    end
  end
end
