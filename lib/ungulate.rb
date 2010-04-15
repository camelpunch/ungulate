require 'rubygems'
require 'ungulate/server'

module Ungulate
end

if defined? Rails
  return if ActionView::Base.instance_methods.include_method? :ungulate_upload_form_for
  require 'ungulate/view_helpers'
  ActionView::Base.send :include, ViewHelpers
end
