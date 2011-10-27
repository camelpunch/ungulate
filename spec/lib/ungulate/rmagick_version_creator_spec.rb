require 'spec_helper'
require 'ungulate/rmagick_version_creator'

module Ungulate
  describe RmagickVersionCreator do
    subject do
      RmagickVersionCreator.new(:logger => ::Logger.new(nil))
    end

    def fixture_path(filename)
      File.expand_path("../../fixtures/#{filename}", File.dirname(__FILE__))
    end

    def fixture(filename)
      File.read fixture_path(filename)
    end

    shared_examples_for "an image converter" do
      it "creates a matching blob" do
        new_blob = subject.create(original, instructions)[:blob]

        expected_image = Magick::Image.from_blob(converted).first
        got_image = Magick::Image.from_blob(new_blob).first

        expected_image.difference(got_image)

        puts "good image:"
        puts "mean per pixel: #{expected_image.mean_error_per_pixel}"
        puts "normalized mean: #{expected_image.normalized_mean_error}"
        puts "normalized max: #{expected_image.normalized_maximum_error}"

        expected_image.mean_error_per_pixel.round.should be_zero
        expected_image.normalized_maximum_error.round.should be_zero

        expected_image.destroy!
        got_image.destroy!
      end

      context "for a png" do
        it "includes image/png as the content-type in the return hash" do
          subject.create(original, instructions)[:content_type].
            should == 'image/png'
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
      let(:converted) { fixture 'chuckle_thumbnail.png' }
      let(:instructions) { [ :resize_to_fill, 80, 80 ] }
      it_behaves_like "an image converter"
    end

    context "resize to fit and then composite" do
      let(:original) { fixture 'chuckle.png' }
      let(:converted) { fixture 'chuckle_converted.png' }
      let(:bad) { fixture 'chuckle_converted_badly.png' }

      let(:instructions) do
        url = "https://dmxno528jhfy0.cloudfront.net/superhug-watermark.png"
        [
          [ :resize_to_fit, 628, 464 ],
          [ :composite, url, :center_gravity, :soft_light_composite_op ]
        ]
      end

      it_behaves_like "an image converter"

      it "doesn't compare well with a broken image" do
        new_blob = subject.create(original, instructions)[:blob]
        got_image = Magick::Image.from_blob(new_blob).first
        bad_image = Magick::Image.from_blob(bad).first

        bad_image.difference(got_image)

        puts "bad image:"
        puts "mean per pixel: #{bad_image.mean_error_per_pixel}"
        puts "normalized mean: #{bad_image.normalized_mean_error}"
        puts "normalized max: #{bad_image.normalized_maximum_error}"

        bad_image.mean_error_per_pixel.round.should > 0
        bad_image.normalized_maximum_error.round.should > 0

        bad_image.destroy!
        got_image.destroy!
      end
    end
  end
end
