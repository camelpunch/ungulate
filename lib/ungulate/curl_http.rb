require 'curb'

module Ungulate
  class CurlHttp
    def initialize
      @easy = Curl::Easy
    end

    def get_body(url)
      @easy.http_get(url).body_str
    end

    def put(url)
      @response = @easy.http_put(url, '')
      self
    end

    def code
      @response.response_code
    end
  end
end
