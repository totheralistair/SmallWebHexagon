require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'

require_relative '../src/muffinland5.rb'

class TestRequests < Test::Unit::TestCase
  include Rack::Test::Methods

  def run_without_server(app, method, route, params={})    # parameterized for GETs and POSTs
    aRequest = Rack::MockRequest.new(app)
    aRequest.request(method, route, {:params=>params})
  end


#=================================================
  def test_00_get_without_server
    viewsFolder = "../src/views/"
    app = Muffinland.new(viewsFolder)

    dynamic_page = page_from_template( viewsFolder + "simpleGET.erb" )
    path = '/a'
    params = '{"d"=>"e", "b"=>"c"}'
    expected = dynamic_page.result(binding())
    run_without_server( app, "GET", '/a?b=c', "d=e").body.should == expected
  end

  def test_01_post_without_server
    viewsFolder = "../src/views/"
    app = Muffinland.new(viewsFolder)

    path = '/login'
    params = '{"login"=>"Wow"}'
    dynamic_page = page_from_template( viewsFolder + "testDataInputResponse1.erb" )
    exp = dynamic_page.result(binding())
    puts "EXPECTED: "
    puts exp

    got = run_without_server( app, "POST", '/login', "login=WoW").body
    puts ".........."
    puts "GOT: "
    puts got
    got.should == exp
  end

end

