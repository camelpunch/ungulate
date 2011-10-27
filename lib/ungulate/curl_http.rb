require 'curb'

module Ungulate
  class CurlHttp
    def initialize(options = {})
      @easy = Curl::Easy
      @logger = options[:logger] || ::Logger.new($stdout)
    end

    def get_body(url)
      @logger.info "GET via HTTP: #{url}"
      @easy.http_get(url).body_str
    end

    def put(url)
      @logger.info "PUT #{url}"
      @response = @easy.http_put(url, '')
      self
    end

    def code
      @response.response_code
    end
  end
end
