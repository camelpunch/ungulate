require 'curb'

module Ungulate
  class CurlHttp
    def initialize
      @easy = Curl::Easy
    end

    def get_body(url)
      @easy.http_get(url).body_str
    end
  end
end
