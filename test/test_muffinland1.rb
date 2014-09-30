require 'rack/test'
require 'rspec/expectations'
require 'test/unit'

require_relative '../src/muffinland1.rb'

class TestRequests < Test::Unit::TestCase
  include Rack::Test::Methods

  def run_without_server(app, method, route, params={})    # parameterized for GETs and POSTs
    aRequest = Rack::MockRequest.new(app)
    aRequest.request(method, route, {:params=>params})
  end

  def run_with_server(app, method, route, params={})      # still only GETs
    aSession = Rack::Test::Session.new(app)
    aSession.request route, {:method=>method}.merge(:params=>params)
  end

# p.s. I don't understand the difference above between MockRequest and Session

#=================================================
  def test_00_get_without_server
    app = Muffinland.new
    run_without_server( app, "GET", '/blarg?A=aa&B=bb', "getKey=getValue").body.should ==
        "Nice GET there. Page requested = /blarg. Params = {\"getKey\"=>\"getValue\", \"A\"=>\"aa\", \"B\"=>\"bb\"}. Bests. Alistair."
    run_without_server( app, "POST", '/ook', "postKey=postValue" ).body.should ==
        "Got that POST, baby. Page requested = /ook. Params = {\"postKey\"=>\"postValue\"}. "
  end

  def test_01_RUN_with_server
    app = Muffinland.new
    run_with_server( app, "GET", '/sweetie?A=a&B=b', "getKey=getValue").body.should ==
        "Nice GET there. Page requested = /sweetie. Params = {\"getKey\"=>\"getValue\", \"A\"=>\"a\", \"B\"=>\"b\"}. Bests. Alistair."
    run_with_server( app, "POST", '/narf', "postKey=postValue").body.should ==
        "Got that POST, baby. Page requested = /narf. Params = {\"postKey\"=>\"postValue\"}. "
  end
end

