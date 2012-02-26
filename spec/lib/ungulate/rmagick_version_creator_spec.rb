require 'spec_helper'
require 'ungulate/rmagick_version_creator'

describe Ungulate::RmagickVersionCreator do
  subject do
    Ungulate::RmagickVersionCreator.new(:logger => ::Logger.new(nil),
                                        :http => http)
  end

  let(:http) { double 'http' }

  let(:new_blob) { subject.create(original, instructions)[:blob] }

  shared_examples_for "an image converter" do
    it "creates a matching blob" do
      expected_image = Magick::Image.from_blob(comparison).first
      got_image = Magick::Image.from_blob(new_blob).first

      expected_image.difference(got_image)

      expected_image.mean_error_per_pixel.round.should be_zero
      expected_image.normalized_maximum_error.round.should be_zero

      expected_image.destroy!
      got_image.destroy!
    end

    context "for a png" do
      it "includes image/png as the content-type in the return hash" do
        image = subject.create(original, instructions)
        image[:content_type].should == 'image/png'
      end
    end

    context "for a jpeg" do
      let(:original) { fixture 'chuckle.jpg' }

      it "includes image/jpeg as the content-type in the return hash" do
        subject.create(original, instructions)[:content_type].
          should == 'image/jpeg'
      end
    end
  end

  context "resize to fill only" do
    let(:original) { fixture 'chuckle.png' }
    let(:comparison) { fixture 'chuckle_thumbnail.png' }
    let(:instructions) { [ :resize_to_fill, 80, 80 ] }
    it_behaves_like "an image converter"
  end

  context "JPEG quality setting" do
    let(:original) { fixture 'sofa.jpg' }

    def blob_of_quality(quality)
      subject.create(
        original,
        [ :resize_to_fit, 100, 200, { :quality => quality.to_s } ]
      )[:blob]
    end

    it "produces a smaller file when reduced" do
      blob_of_quality(74).size.should < blob_of_quality(75).size
    end

    it "produces the same sized file when the same" do
      blob_of_quality(75).size.should == blob_of_quality(75).size
    end

    context "when source image is a PNG" do
      let(:original) { fixture 'chuckle.png' }

      it "does not change the file size when reduced" do
        blob_of_quality(1).size.should == blob_of_quality(75).size
      end
    end
  end

  context "resize to fit and then composite" do
    let(:url) { "https://some/watermark.png" }
    let(:original) { fixture 'chuckle.png' }
    let(:comparison) { fixture 'chuckle_converted.png' }
    let(:bad) { fixture 'chuckle_converted_badly.png' }

    let(:instructions) do
      [
        [ :resize_to_fit, 628, 464 ],
        [ :composite, url, :center_gravity, :soft_light_composite_op ]
      ]
    end

    before do
      http.should_receive(:get_body).with(url).and_return fixture('watermark.png')
    end

    it_behaves_like "an image converter"

    it "doesn't compare well with a broken image" do
      got_image = Magick::Image.from_blob(new_blob).first
      bad_image = Magick::Image.from_blob(bad).first

      bad_image.difference(got_image)

      bad_image.mean_error_per_pixel.round.should > 0
      bad_image.normalized_maximum_error.round.should > 0

      bad_image.destroy!
      got_image.destroy!
    end
  end
end
