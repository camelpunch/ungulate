require 'rubygems'
require 'ungulate/server'

module Ungulate
end

if defined? ActionView::Base
  require 'ungulate/view_helpers'
  ActionView::Base.send :include, ViewHelpers
end
