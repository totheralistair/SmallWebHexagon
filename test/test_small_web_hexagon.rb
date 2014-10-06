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
  rr = Rack::Request.new(env)
  request = Ml_RackRequest.new( rr )
end


# {:a=>1, :b=>2, :c=>3}.slice_per({:b=y, :c=>z}) returns {:b=>2, :c=>3}
def slice_per( valuesHash, keysHash )
  keysHash.inject({}) { |subset, (k,v) | subset[k] = valuesHash[k] ; subset }
end


def expecting( fatHash, thinHash )
  slice_per( fatHash, thinHash ).should == thinHash
end


class TestRequests < Test::Unit::TestCase

  def test_00_emptyDB_is_special_case
    app = Smallwebhexagon.new

    mlResponse = app.handle construct_request(  "GET", '/aaa' )
    expecting( mlResponse,
               {out_action:  "EmptyDB"}
    )

  end


  def test_01_posts_return_contents
    app = Smallwebhexagon.new

    mlResponse = app.handle construct_request(  "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    expecting( mlResponse,
               {
                   out_action:   "GET_named_page",
                   muffin_id:   0,
                   muffin_body: "a"
               }
    )

    mlResponse = app.handle construct_request(  "POST", '/stillignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    expecting( mlResponse,
               {
                   out_action:   "GET_named_page",
                   muffin_id:   1,
                   muffin_body: "b"
               }
    )

    mlResponse = app.handle construct_request(  "GET", '/0' )
    expecting( mlResponse,
               {
                   out_action:   "GET_named_page",
                   muffin_id:   0,
                   muffin_body: "a"
               }
    )

    mlResponse = app.handle construct_request(  "GET", '/1' )
    expecting( mlResponse,
               {
                   out_action:   "GET_named_page",
                   muffin_id:   1,
                   muffin_body: "b"
               }
    )

    mlResponse = app.handle construct_request(  "GET", '/2' )
    expecting( mlResponse,
               {
                   out_action:   "404"
               }
    )
  end


  def test_02_can_load_history_externally
    app = Smallwebhexagon.new
    history = [ construct_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" }) ]
    app.use_history history

    mlResponse = app.handle construct_request(  "GET", '/0' )
    expecting( mlResponse,
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
    app.use_history history

    mlResponse = app.handle construct_request(  "GET", '/1' )
    history.should be_empty # GET does not add to history

    request0 = construct_request( "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    mlResponse = app.handle request0
    history[0].should == request0 # but POST does
  end

=begin
#====== BROKEN FROM HERE ON DOWN ======
  def test_06_can_load_history_from_files
    return

    app = Smallwebhexagon.new

    request = construct_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })

#    p request
#    puts Marshal.dump(request)

    FileUtils.rm('warehouse.txt') if File.file?('warehouse.txt')
    File.open('warehouse.txt', 'w') do |f|
      f << YAML.dump(request)
    end
    warehouse = File.open('warehouse.txt')

    warehouse.should_not be_nil

    warehouse.extend FileWarehouse

    app.use_history warehouse

    mlResponse = request_via_API( app, "GET", '/0' )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        muffin_body: "apple"
    }
    mlResponse.slice_per( exp ).should == exp
  end

#=================================================
=end


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
