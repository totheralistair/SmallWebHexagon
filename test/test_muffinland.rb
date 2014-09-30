require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'

require_relative '../src/muffinland.rb'
require_relative '../src/ml_request.rb'

#=== utilities ======================
class Hash
def extract_per( sampleHash )  # {:a=>1, :b=>2, :c=>3}.extract_per({:b=y, :c=>z}) returns {:b=>2, :c=>3}
    sampleHash.inject({}) { |subset, (k,v) | subset[k] = self[k] ; subset }
  end
end


#=== different ways of driving the app ======================
def request_via_API( app, method, path, params={} ) # app should be Muffinland (hexagon API)
  env = Rack::MockRequest.env_for(path, {:method => method, :params=>params}  )
  rr = Rack::Request.new(env)
  request = Ml_RackRequest.new( rr )
  app.handle request
end


def request_via_rack_without_server( app, method, path, params={} ) # app should be Muffinland_via_rack
  request = Rack::MockRequest.new(app)
  request.request(method, path, {:params=>params}) #this sends the request through the Rack call(env) chain
end



class TestRequests < Test::Unit::TestCase
#=================================================
  def test_00_emptyDB_is_special_case
    puts "test_00_emptyDB starting..."
    t0=Time.now.to_f

    app = Muffinland.new

    mlResponse = request_via_API( app, "GET", '/' )
    exp = {out_action:  "EmptyDB"}
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/aaa' )
    exp =  {out_action:  "EmptyDB"}
    mlResponse.extract_per( exp ).should == exp

    t1=Time.now.to_f
    puts "test_00_emptyDB done. #{((t1-t0)*1000).round(2)}"
  end


#=================================================
  def test_01_posts_return_contents
    puts "test_01_posts starting..."
    t0=Time.now.to_f

    app = Muffinland.new

    mlResponse = request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        dangerously_all_muffins_for_viewing:   ["a"]
    }
    mlResponse.extract_per( exp ).should == exp


    mlResponse = request_via_API( app, "POST", '/stillignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    exp = {
    out_action:   "GET_named_page",
    muffin_id:   1,
    dangerously_all_muffins_for_viewing:   ["a", "b"]
    }
    mlResponse.extract_per( exp ).should == exp

    t1=Time.now.to_f
    puts "test_01_posts done. #{((t1-t0)*1000).round(2)}"
  end


#=================================================
  def test_02_can_post_and_get_even_404
    puts "test_02_postAndGet starting..."
    t0=Time.now.to_f

    app = Muffinland.new

    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"c" } )
    mlResponse = request_via_API( app, "GET", '/1' )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   1,
        muffin_body:   "b",
        dangerously_all_muffins_for_viewing:   ["a", "b", "c"]
    }
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/77' )
    exp = {
        out_action:   "404",
        muffin_id:   nil,
        muffin_body:   nil,
        dangerously_all_muffins_for_viewing:   ["a", "b", "c"]
    }
    mlResponse.extract_per( exp ).should == exp

    t1=Time.now.to_f
    puts "test_02_postAndGet done. #{((t1-t0)*1000).round(2)}"
  end


#=================================================


end

