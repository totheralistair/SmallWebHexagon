require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require 'fileutils'
require 'yaml'
require_relative '../src/smallwebhexagon.rb'
require_relative '../src/smallwebhexagon_via_rack.rb'
require_relative '../src/ml_request'
Test::Unit::TestCase.include RSpec::Matchers


class TestRequests < Test::Unit::TestCase
  attr_accessor :app

  #------ utilities ---------

  def new_ml_request method, path, params={}
    Ml_RackRequest.new  Rack::MockRequest.env_for( path, {:method => method, :params=>params} )
  end

  def sending_expect method, path, params, expectedResult
    (app.handle new_ml_request( method, path, params ) ).
        should include expectedResult
  end


  def request_via_rack_adapter_without_server( app, method, path, params={} ) # app should be Muffinland_via_rack
    request = Rack::MockRequest.new(app)
    request.request(method, path, {:params=>params}) # sends the request through the Rack call(env) chain
  end


  def page_from_template( fn, binding )
    pageTemplate = Erubis::Eruby.new(File.open( fn, 'r').read)
    pageTemplate.result(binding)
  end

  #------ the tests ---------

  def test_z_runs_via_Rack_adapter # just check hexagon integrity, not a data check
    viewsFolder = "../src/views/"
    @app = Smallwebhexagon_via_rack.new(viewsFolder)

    request_via_rack_adapter_without_server( app, "GET", '/a?b=c', "d=e").body.
        should == page_from_template( viewsFolder + "EmptyDB.erb" , binding )
  end


  def test_00_emptyDB_is_special_case
    @app = Smallwebhexagon.new

    sending_expect "GET", '/aaa', {} ,
                   {
                       out_action:  "EmptyDB"
                   }
  end


  def test_01_posts_return_contents
    @app = Smallwebhexagon.new

    sending_expect "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" },
                    {
                        out_action:   "GET_named_page",
                        muffin_id:   0,
                        muffin_body: "a"
                    }

    sending_expect "POST", '/stillignored',{ "Add"=>"Add", "MuffinContents"=>"b" },
                    {
                        out_action:   "GET_named_page",
                        muffin_id:   1,
                        muffin_body: "b"
                    }

    sending_expect "GET", '/0', {},
              {
                  out_action:   "GET_named_page",
                  muffin_id:   0,
                  muffin_body: "a"
              }

    sending_expect "GET", '/1', {},
                    {
                        out_action:   "GET_named_page",
                        muffin_id:   1,
                        muffin_body: "b"
                    }

    sending_expect "GET", '/2', {},
                    {
                        out_action:   "404"
                    }


  end


  def test_02_can_load_history_externally
    @app = Smallwebhexagon.new
    history = [ new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" }) ]

    app.dangerously_replace_history history

    sending_expect "GET", '/0', {},
                    {
                        out_action:   "GET_named_page",
                        muffin_id:   0,
                        muffin_body: "apple"
                    }
  end


  def test_03_historian_adds_to_history
    @app = Smallwebhexagon.new
    history = []
    app.dangerously_replace_history history

    request = new_ml_request(  "GET", '/1',{} )
    app.handle request
    history.should == []

    request = new_ml_request( "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    app.handle request
    history[0].should == request
  end

#====== BROKEN FROM HERE ON DOWN ======
  def test_06_can_load_history_from_files
    return

    app = Smallwebhexagon.new

    request = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })

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
