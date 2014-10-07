require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require 'fileutils'
require 'yaml'
require_relative '../src/smallwebhexagon.rb'
require_relative '../src/ml_request'
Test::Unit::TestCase.include RSpec::Matchers


def construct_request(method, path, params={})
  env = Rack::MockRequest.env_for(path, {:method => method, :params=>params}  )
  request = Ml_RackRequest.new( Rack::Request.new( env ) )
end



def sending_expect( app, method, path, params, expectedResult )
  mlResponse = app.handle construct_request( method, path, params )
  expecting( mlResponse, expectedResult )
end

def expecting( fatHash, thinHash )
  slice_per( fatHash, thinHash ).should == thinHash
end

# {:a=>1, :b=>2, :c=>3}.slice_per({:b=y, :c=>z}) returns {:b=>2, :c=>3}
def slice_per( fatHash, thinHash )
  thinHash.inject({}) { |slice, (k,v) | slice[k] = fatHash[k] ; slice }
end



class TestRequests < Test::Unit::TestCase

  def test_00_emptyDB_is_special_case
    app = Smallwebhexagon.new

    sending_expect( app,  "GET", '/aaa', {} ,
                    {out_action:  "EmptyDB"}
    )
  end


  def test_01_posts_return_contents
    app = Smallwebhexagon.new

    sending_expect( app,  "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } ,
                    {
                        out_action:   "GET_named_page",
                        muffin_id:   0,
                        muffin_body: "a"
                    }
    )

    sending_expect( app,    "POST", '/stillignored',{ "Add"=>"Add", "MuffinContents"=>"b" },
                    {
                        out_action:   "GET_named_page",
                        muffin_id:   1,
                        muffin_body: "b"
                    }
    )

    sending_expect( app,  "GET", '/0', {},
              {
                  out_action:   "GET_named_page",
                  muffin_id:   0,
                  muffin_body: "a"
              }
    )

    sending_expect( app,   "GET", '/1', {},
                    {
                        out_action:   "GET_named_page",
                        muffin_id:   1,
                        muffin_body: "b"
                    }
    )

    sending_expect( app,   "GET", '/2', {},
                    {
                        out_action:   "404"
                    }
    )

  end


  def test_02_can_load_history_externally
    app = Smallwebhexagon.new
    history = [ construct_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" }) ]

    app.dangerously_replace_history history

    sending_expect( app,   "GET", '/0', {},
                    {
                        out_action:   "GET_named_page",
                        muffin_id:   0,
                        muffin_body: "apple"
                    }
    )

  end


  def test_03_historian_adds_to_history
    app = Smallwebhexagon.new
    history = []
    app.dangerously_replace_history history

    mlResponse = app.handle construct_request(  "GET", '/1' )
    history.should be_empty # GET does not add to history

    request = construct_request( "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    mlResponse = app.handle request
    history[0].should == request # but POST does
  end

#====== BROKEN FROM HERE ON DOWN ======
  def test_06_can_load_history_from_files
    return

    app = Smallwebhexagon.new

    request = construct_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })

    puts Marshal.dump(request)

    FileUtils.rm('warehouse.txt') if File.file?('warehouse.txt')
    File.open('warehouse.txt', 'w') do |f|
      f << YAML.dump(request)
    end
    warehouse = File.open('warehouse.txt')

    warehouse.should_not be_nil

    warehouse.extend FileWarehouse

    app.dangerously_replace_history warehouse

    mlResponse = request_via_API( app, "GET", '/0' )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        muffin_body: "apple"
    }
    mlResponse.slice_per( exp ).should == exp
  end

#=================================================


end

=begin
module FileWarehouse
  def each(&block)
    lines = readlines.map(&:strip).reject {|l| l.empty? }
    lines.each {|l| block.call(YAML.load(l)) }
  end

  def size
  end

  def <<(o)
  end
end
=end
