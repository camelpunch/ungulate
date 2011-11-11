require 'excon'

module Ungulate
  class Http
    def initialize(options = {})
      @logger = options[:logger] || ::Logger.new($stdout)
    end

    def get_body(url)
      @logger.info "GET via HTTP: #{url}"
      Excon.get(url).body
    end

    def put(url)
      @logger.info "PUT #{url}"
      @response = Excon.put(url)
      self
    end

    def code
      @response.status
    end
  end
end
