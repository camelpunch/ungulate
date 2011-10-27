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
        new_blob = subject.create(original, instructions)

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
        expected_image = Magick::Image.from_blob(converted).first
        bad_image = Magick::Image.from_blob(bad).first

        expected_image.difference(bad_image)

        puts "bad image:"
        puts "mean per pixel: #{expected_image.mean_error_per_pixel}"
        puts "normalized mean: #{expected_image.normalized_mean_error}"
        puts "normalized max: #{expected_image.normalized_maximum_error}"

        expected_image.mean_error_per_pixel.round.should > 0
        expected_image.normalized_maximum_error.round.should > 0

        expected_image.destroy!
        bad_image.destroy!
      end
    end
  end
end
