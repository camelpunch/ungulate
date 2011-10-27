require 'tempfile'

TEST_FILE = Tempfile.new('put request')

pid = fork do
  require 'webrick'

  class PutServlet < WEBrick::HTTPServlet::AbstractServlet
    def do_PUT(req, resp)
      TEST_FILE << req.request_uri
      TEST_FILE.close
      raise WEBrick::HTTPStatus::OK
    end
  end

  server = WEBrick::HTTPServer.new(:Port => 9999)
  server.mount('/bob', PutServlet)
  server.start
end

at_exit { Process.kill('KILL', pid) }

