require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require_relative '../src/muffinland.rb'
require_relative '../src/ml_request'


def request_via_API( app, method, path, params={} ) # app should be Muffinland (hexagon API)
  env = Rack::MockRequest.env_for(path, {:method => method, :params=>params}  )
  rr = Rack::Request.new(env)
  request = Ml_RackRequest.new( rr )
  app.handle request
end

class Hash
  # {:a=>1, :b=>2, :c=>3}.extract_per({:b=y, :c=>z}) returns {:b=>2, :c=>3}
  def extract_per( sampleHash )
    sampleHash.inject({}) { |subset, (k,v) | subset[k] = self[k] ; subset }
  end
end




class TestRequests < Test::Unit::TestCase

  def test_00_emptyDB_is_special_case
    app = Muffinland.new
    mlResponse = request_via_API( app, "GET", '/' )
    exp = {out_action:  "404"}
    mlResponse.extract_per( exp ).should == exp
  end


  def test_01_posts_return_contents
    app = Muffinland.new

    mlResponse = request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        muffin_body: "a"
    }
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "POST", '/stillignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   1,
        muffin_body: "b"
    }
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/0' )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        muffin_body: "a"
    }
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/1' )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   1,
        muffin_body: "b"
    }
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/2' )
    exp = {
        out_action:   "404"
    }
    mlResponse.extract_per( exp ).should == exp


  end



#=================================================


end

