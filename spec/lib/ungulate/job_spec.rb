require 'spec_helper'
require 'ungulate/job'

module Ungulate
  describe Job do
    let(:source_image) { stub('Source Image', :destroy! => nil) }
    let(:processed_image_1) { stub('Image 1', :destroy! => nil) }
    let(:processed_image_2) { stub('Image 2', :destroy! => nil) }
    let(:curl_easy) { stub('Curl::Easy', :body_str => body_str) }

    before do
      ENV['AMAZON_ACCESS_KEY_ID'] = 'test-key-id'
      ENV['AMAZON_SECRET_ACCESS_KEY'] = 'test-secret'
      @bucket = mock('Bucket', :put => nil)
      @sqs = mock('SqsGen2')
      @s3 = mock('S3')
      @q = mock('Queue')
      @versions = {
        :thumb => [ :resize_to_fit, 100, 200 ],
        :large => [ :resize_to_fit, 200, 300 ],
      }

      Curl::Easy.stub(:http_get)
    end

    its(:versions) { should == [] }

    context "new API" do
      subject do
        Job.new(:image_processor => image_processor, :storage => storage,
                :http => http, :logger => ::Logger.new(nil))
      end

      let(:http) { double 'http' }
      let(:image_processor) { double 'image_processor' }
      let(:storage) { double 'storage', :bucket => bucket }
      let(:bucket) { double 'bucket', :retrieve => nil }
      let(:versions) do
        {
          :large => [ :resize_to_fill, 400, 300 ],
          :medium => [ :resize_to_fit, 300, 200 ],
          :thumbnail => [ :resize_to_fit, 40, 20 ]
        }
      end
      let(:job_description) do
        {
          :bucket => 'some-bucket',
          :key => 'original-key.jpg',
          :versions => versions
        }
      end
      let(:job_encoded) { job_description.to_yaml }

      it "gets an original blob and sends it to be processed" do
        blob = double 'blob'

        storage.should_receive(:bucket).with('some-bucket').and_return(bucket)
        bucket.should_receive(:retrieve).with('original-key.jpg').and_return(blob)

        image_processor.should_receive(:process).
          with(:blob => blob, :versions => versions, :bucket => bucket,
               :listener => subject)

        subject.process(job_encoded)
      end

      context "with no notification URL" do
        it "accepts storage complete messages, but does nothing" do
          storage.stub(:get)
          image_processor.stub(:process)
          subject.process(job_encoded)
          subject.storage_complete(:large)
          subject.storage_complete(:medium)

          http.should_not_receive(:put)
          subject.storage_complete(:thumbnail)
        end
      end

      context "when notification URL set" do
        let(:job_description) do
          {
            :bucket => 'some-bucket',
            :key => 'original-key.jpg',
            :notification_url => 'http://some.url',
            :versions => versions
          }
        end

        before do
          storage.stub(:get)
          image_processor.stub(:process)
          subject.process(job_encoded)
        end

        context "with only one version" do
          let(:versions) { { :large => [ :resize_to_fill, 400, 300 ] } }

          it "PUTs to the notification URL when only version stored" do
            http.should_receive(:put).with('http://some.url')
            subject.storage_complete(:large)
          end
        end

        context "with three versions" do
          let(:versions) do
            {
              :large => [ :resize_to_fill, 400, 300 ],
              :medium => [ :resize_to_fit, 300, 200 ],
              :thumbnail => [ :resize_to_fit, 40, 20 ]
            }
          end

          it "PUTs to the notification URL when third version stored" do
            subject.storage_complete(:large)
            subject.storage_complete(:medium)

            http.should_receive(:put).with('http://some.url')
            subject.storage_complete(:thumbnail)
          end
        end

        context "with a different URL" do
          let(:job_description) do
            {
              :bucket => 'some-bucket',
              :key => 'original-key.jpg',
              :notification_url => 'http://some.other.url',
              :versions => versions
            }
          end

          it "uses the other URL" do
            subject.storage_complete(:large)
            subject.storage_complete(:medium)
            http.should_receive(:put).with('http://some.other.url')
            subject.storage_complete(:thumbnail)
          end
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

      it "should memoize" do
        Job.instance_variable_set('@s3', :cache)
        Job.s3.should == :cache
      end
    end

    describe :source do
      subject do
        job = Job.new
        job.stub(:key).and_return('test-key')
        job.stub_chain(:bucket, :get).with('test-key').and_return(:s3_data)
        job.source
      end

      it { should == :s3_data }

      it "should memoize" do
        job = Job.new
        job.instance_variable_set('@source', :cache)
        job.source.should == :cache
      end
    end

    describe :image do
      let(:blob) { 'asdf' }

      it "returns a Magick::Image from the source" do
        subject.stub(:source).and_return(blob)
        Magick::Image.should_receive(:from_blob).with(blob).and_return([source_image])
        subject.source_image.should == source_image
      end
    end

    describe :image_from_instruction do
      let(:instruction) { [ :composite, url, arg1, arg2 ] }
      let(:overlay) { stub('Overlay', :destroy! => nil) }
      let(:arg1) { 1 }
      let(:arg2) { 2 }
      let(:url) { 'https://www.some.url/' }
      let(:body_str) { 'blob' }

      before do
        Curl::Easy.stub(:http_get).and_return(curl_easy)
        Magick::Image.stub(:from_blob).and_return([overlay])
        source_image.stub(:composite).and_return(processed_image_1)
      end

      context "when an argument is a URL" do
        it "converts the URL to an Image" do
          Curl::Easy.should_receive(:http_get).with(url).and_return(curl_easy)
          Magick::Image.should_receive(:from_blob).with('blob').and_return([overlay])
          source_image.should_receive(:composite).
            with(overlay, arg1, arg2).
            and_return(processed_image_1)

          subject.image_from_instruction(source_image, instruction).
            should == processed_image_1
        end

        it "caches the image blob in a hash for later reuse" do
          subject.image_from_instruction(source_image, instruction)
          Ungulate::Job.blobs_from_urls[url].should == 'blob'
        end

        context "image is already cached" do
          it "reuses the cached image" do
            subject.class.blobs_from_urls[url] = 'cachedblob'
            Magick::Image.should_receive(:from_blob).with('cachedblob').and_return([overlay])
            subject.image_from_instruction(source_image, instruction)
          end
        end
      end

      context "when argument isn't a valid http URL" do
        let(:url) { 'somethingwithhttpinit' }

        it "passes the argument through to the method" do
          source_image.should_receive(:composite).
            with(url, arg1, arg2).
            and_return(processed_image_1)

          subject.image_from_instruction(source_image, instruction)
        end
      end

      context "when arguments are symbols" do
        let(:arg1) { :center_gravity }
        let(:arg2) { :soft_light_composite_op }

        it "converts the symbols to Magick::XxXx constants" do
          source_image.should_receive(:composite).
            with(anything, Magick::CenterGravity, Magick::SoftLightCompositeOp).
            and_return(processed_image_1)

          subject.image_from_instruction(source_image, instruction)
        end
      end
    end

    describe :processed_versions do
      let(:versions) do
        {
          :large => [ :resize_to_fit, 100, 200 ],
          :small => [ :resize_to_fill, 64, 64 ],
        }
      end

      before do
        subject.stub(:versions).and_return(versions)
        subject.stub(:key).and_return('someimage.jpg')
        subject.stub(:source_image).and_return(source_image)

        source_image.stub(:resize_to_fit).with(100, 200).and_return(processed_image_1)
        source_image.stub(:resize_to_fill).with(64, 64).and_return(processed_image_2)
      end

      it "processes multiple versions" do
        subject.processed_versions.should include([:large, processed_image_1])
        subject.processed_versions.should include([:small, processed_image_2])
      end

      it "destroys the image object" do
        source_image.should_receive(:destroy!)
        subject.processed_versions
      end

      it "memoizes" do
        subject.instance_variable_set('@processed_versions', :cache)
        subject.processed_versions.should == :cache
      end

      context "with three 'method' arguments" do
        let(:versions) do
          { :large => [ :some_method, 'some-value', 1, 2 ] }
        end

        it "passes each value" do
          source_image.should_receive(:some_method).
            with('some-value', 1, 2).
            and_return(processed_image_1)
          subject.processed_versions.should == [[:large, processed_image_1]]
        end
      end

      context "with multiple instructions in a version" do
        let(:versions) do
          {
            :large => [
              [ :method_1, 'value-1' ],
              [ :method_2, 'value-2' ]
            ]
          }
        end

        before do
          source_image.stub(:method_1).and_return(processed_image_1)
          processed_image_1.stub(:method_2).and_return(processed_image_2)
        end

        it "chains the processing" do
          subject.processed_versions.should == [[:large, processed_image_2]]
        end

        it "destroys intermediate images" do
          processed_image_1.should_receive(:destroy!)
          subject.processed_versions
        end
      end
    end

    describe :process do
      before do
        pending
        @big = mock('Image', :destroy! => nil, :to_blob => 'bigdata', :format => 'JPEG')
        @little = mock('Image', :destroy! => nil, :to_blob => 'littledata', :format => 'JPEG')
        @mime_type = mock('MimeType', :to_s => 'image/jpeg')
        MIME::Types.stub(:type_for).with('JPEG').and_return(@mime_type)
      end

      subject do
        job = Job.new
        job.stub(:processed_versions).and_return([[:big, @big], [:little, @little]])
        job.stub(:bucket).and_return(@bucket)
        job.stub(:version_key).with(:big).and_return('path/to/someimage_big.jpg')
        job.stub(:version_key).with(:little).and_return('path/to/someimage_little.jpg')
        job.stub(:send_notification)
        job
      end

      it "should destroy the image objects" do
        @big.should_receive(:destroy!)
        @little.should_receive(:destroy!)
        subject.process
      end

      it "should send each processed version to S3" do
        expected_headers = {
          'Content-Type' => 'image/jpeg',
          'Cache-Control' => 'max-age=2629743',
        }

        @bucket.should_receive(:put).with('path/to/someimage_big.jpg', 
                                          'bigdata',
                                          {},
                                          'public-read',
                                          expected_headers)
        @bucket.should_receive(:put).with('path/to/someimage_little.jpg', 
                                          'littledata',
                                          {},
                                          'public-read',
                                          expected_headers)
        subject.process
      end

      it "should notify" do
        subject.should_receive(:send_notification)
        subject.process
      end

      context "send_notification returns false" do
        before do
          subject.stub(:send_notification).and_return(false)
        end

        it "should return true" do
          subject.process.should be_true
        end
      end

      context "empty array" do
        before do
          subject.stub(:processed_versions).and_return([])
        end

        it "should not break" do
          subject.process
        end
      end
    end

    describe :send_notification do
      let(:url) { 'https://some-url' }

      context "notification URL provided" do
        it "should PUT to the URL" do
          subject.stub(:notification_url).and_return(url)
          Curl::Easy.should_receive(:http_put).with(url, '')
          subject.send_notification
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
