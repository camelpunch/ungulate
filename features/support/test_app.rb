require 'sinatra'
require File.expand_path('../../config/ungulate', File.dirname(__FILE__))
require 'ungulate/view_helpers'
require 'ungulate/file_upload'
require 'active_support/log_subscriber'
require 'active_support/memoizable'
require 'active_support/concern'
require 'active_support/dependencies/autoload'
require 'action_view/asset_paths'
require 'action_view/context'
require 'action_view/helpers'
require 'action_view/helpers/text_helper'
require 'action_view/base'
require 'action_view/buffers'
require 'active_support/core_ext/numeric/time'

class TestApp < Sinatra::Base
  attr_accessor :output_buffer

  include Ungulate::ViewHelpers
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::CaptureHelper

  get '/' do
    key = Ungulate.configuration.test_upload_key

    upload = Ungulate::FileUpload.new(
      :bucket_url => "https://#{Ungulate.configuration.test_bucket}.s3.amazonaws.com/",
      :key => key,
      :policy => {
        'expiration' => 2.minutes.from_now,
        'conditions' => [
          {'bucket' => Ungulate.configuration.test_bucket},
          {'key' => key},
          {'acl' => 'private'},
          {'success_action_redirect' =>
            "http://localhost:9999#{Ungulate.configuration.test_success_action_redirect_path}"}
        ]
      }
    )

    ungulate_upload_form_for(upload) do
      %Q(
      <input type="file" name="file" />
      <input type="submit" id="submit" value="Submit" />
      ).html_safe
    end
  end
end
