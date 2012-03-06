require 'spec_helper'
require 'ungulate/blob_processor'

describe Ungulate::BlobProcessor do
  subject { Ungulate::BlobProcessor.new(:version_creator => creator) }

  let(:creator) { double 'version creator' }
  let(:bucket) { double 'bucket' }
  let(:blob) { 'asdf' }

  it "processes a blob into several versions and sends them to storage" do
    large = [
      [ :resize_to_fill, 400, 300 ],
      [ :composite, 'http://some.image/url.jpg', :center_gravity, :soft_light_composite_op ],
    ]
    medium = [ :resize_to_fit, 300, 200 ]
    thumbnail = [ :resize_to_fit, 40, 20 ]

    versions = {
      :large => large,
      :medium => medium,
      :thumbnail => thumbnail
    }

    creator.should_receive(:create).with(blob, large).
      and_return(:blob => 'largeblob', :content_type => 'image/png')

    creator.should_receive(:create).with(blob, medium).
      and_return(:blob => 'mediumblob', :content_type => 'image/jpeg')

    creator.should_receive(:create).with(blob, thumbnail).
      and_return(:blob => 'thumbnailblob', :content_type => 'application/xml')

    bucket.should_receive(:store).
      with('some/file_large.jpg', 'largeblob', :version => :large,
           :content_type => 'image/png')

    bucket.should_receive(:store).
      with('some/file_medium.jpg', 'mediumblob', :version => :medium,
           :content_type => 'image/jpeg')

    bucket.should_receive(:store).
      with('some/file_thumbnail.jpg', 'thumbnailblob', :version => :thumbnail,
           :content_type => 'application/xml')

    subject.process(
      :blob => blob, :versions => versions,
      :original_key => 'some/file.jpg', :bucket => bucket
    )
  end

  context "when key has no leading path" do
    it "converts the key properly" do
      creator.stub(:create).and_return({})

      bucket.should_receive(:store).with('file_large.jpg', anything, anything)

      subject.process(:original_key => 'file.jpg',
                      :blob => blob, :versions => { :large => [] },
                      :bucket => bucket)
    end
  end
end
