require 'spec_helper'
require 'ungulate/job'

describe Ungulate::Job do
  subject do
    Ungulate::Job.new(:blob_processor => blob_processor, :storage => storage,
                      :http => http, :logger => ::Logger.new(nil))
  end

  let(:http) { double 'http' }
  let(:blob_processor) { double 'blob processor' }
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

    storage.should_receive(:bucket).with('some-bucket', :listener => subject).
      and_return(bucket)
    bucket.should_receive(:retrieve).with('original-key.jpg').and_return(blob)

    blob_processor.should_receive(:process).
      with(:blob => blob, :versions => versions, :bucket => bucket,
           :original_key => 'original-key.jpg')

    subject.process(job_encoded)
  end

  context "with no notification URL" do
    it "accepts storage complete messages, but does nothing" do
      storage.stub(:get)
      blob_processor.stub(:process)
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
      blob_processor.stub(:process)
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
