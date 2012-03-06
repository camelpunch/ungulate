require 'RMagick'
require 'active_support/core_ext/string'
require 'mime/types'

module Ungulate
  class RmagickVersionCreator
    def initialize(options = {})
      @logger = options[:logger] || ::Logger.new($stdout)
      @http = options[:http]
    end

    def create(blob, instructions)
      image = processed_image(magick_image_from_blob(blob), instructions)

      {
        :blob => finished_blob_from_image(image),
        :content_type => MIME::Types.type_for(image.format).to_s.gsub(/[\[\]]/, '')
      }
    end

    private

    def finished_blob_from_image(image)
      attributes = @write_attributes

      if attributes && image.format.include?('JPEG')
        image.to_blob { attributes.each_pair {|k, v| send("#{k}=", v.to_i) } }
      else
        image.to_blob
      end
    end

    def blob_from_url(url)
      @blobs_from_urls ||= {}
      @blobs_from_urls[url] ||= @http.get_body(url)
    end

    def magick_image_from_url(url)
      Magick::Image.from_blob(blob_from_url(url)).first
    end

    def instruction_args(args)
      args.map do |arg|
        if arg.is_a?(Symbol)
          "Magick::#{arg.to_s.classify}".constantize
        elsif arg.respond_to?(:match) && arg.match(/^http/)
          magick_image_from_url(arg)
        else
          arg
        end
      end
    end

    def image_from_instruction(original, instruction)
      method, *args = instruction

      @write_attributes = args.pop if args.last.is_a?(Hash)

      send_args = instruction_args(args)

      @logger.info "Performing #{method} with #{args.join(', ')}"
      original.send(method, *send_args).tap do |new_image|
        original.destroy!
        send_args.select {|arg| arg.is_a?(Magick::Image)}.each(&:destroy!)
      end
    end

    def image_from_instruction_chain(original, chain)
      if chain.one?
        image_from_instruction(original, chain.first)
      else
        image_from_instruction_chain(
          image_from_instruction(original, chain.shift),
          chain
        )
      end
    end

    def processed_image(original, instruction)
      if instruction.first.respond_to?(:entries)
        image_from_instruction_chain(original, instruction)
      else
        image_from_instruction(original, instruction)
      end
    end

    def magick_image_from_blob(blob)
      Magick::Image.from_blob(blob).first
    end
  end
end
