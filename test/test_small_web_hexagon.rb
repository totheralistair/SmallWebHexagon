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
    sending_r_expect( new_ml_request( method, path, params ), expectedResult )
  end

  def sending_r_expect ml_req, expectedResult
    (app.handle ml_req ).
        should include expectedResult
  end


  def request_via_rack_adapter_without_server( app, method, path, params={} ) # app should be Muffinland_via_rack
    request = Rack::MockRequest.new(app)
    request.request(method, path, {:params=>params}) # sends the r0 through the Rack call(env) chain
  end

  def page_from_template( fn, binding )
    pageTemplate = Erubis::Eruby.new(File.open( fn, 'r').read)
    pageTemplate.result(binding)
  end

  #------ the tests ---------

  def test_z_runs_via_Rack_adapter # just check hexagon integrity, not a data check
    p "in test z"
    viewsFolder = "../src/views/"
    @app = Smallwebhexagon_via_rack.new(viewsFolder)

    request_via_rack_adapter_without_server( app, "GET", '/a?b=c', "d=e").body.
        should == page_from_template( viewsFolder + "EmptyDB.erb" , binding )
  end


  def test_00_emptyDB_is_special_case
    p "in test 0"
    @app = Smallwebhexagon.new

    sending_expect "GET", '/aaa', {} ,
                   {
                       out_action:  "EmptyDB"
                   }
  end


  def test_01_posts_return_contents
    p "in test 1"
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


  def test_02_requests_serialize_and_reconstitute_back_and_forth
    p "in test 2"
    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    s0 = r0.serialized

    r1 = Ml_RackRequest::reconstitute_from( s0 )
    s1 = r1.serialized

    s0.should == s1
  end



  def test_03_history_dumps_serialized_as_i_expect
    p "in test 3"
    @app = Smallwebhexagon.new

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    s0 = r0.serialized
    app.handle r0
    app.dangerously_serialized_history.should == [ s0 ]

    r1 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"banana" })
    s1 = r1.serialized
    app.handle r1
    app.dangerously_serialized_history.should == [ s0, s1 ]
  end


  def test_04_loads_history_from_array_and_grows_it
    p "in test 4"
    @app = Smallwebhexagon.new

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    s0 = r0.serialized
    app.dangerously_replace_history [ s0 ]

    r1 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"banaba" })
    s1 = r1.serialized
    app.handle r1
    app.dangerously_serialized_history.should == [ s0, s1 ]
  end


  def Failing_test_05_can_load_history_from_files
    @app = Smallwebhexagon.new
    r0 = new_ml_request 'POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" }
    s0 = r0.serialized
    p s0


    #darn. YAML puts \n after things; mucks up my file reading. need new ideas.


    fn = 'mlhistory.txt' ; FileUtils.rm( fn ) if File.file?( fn )
    File.open( fn, 'w') do |f|
      f << s0
      f << s0
    end
    history = File.open( fn )

    app.dangerously_replace_history history

    sending_expect "GET", '/0', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   0,
                       muffin_body: "apple"
                   }

    sending_expect "GET", '/1', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   1,
                       muffin_body: "banana"
                   }

    sending_expect "GET", '/2', {},
                   {
                       out_action:   "404"
                   }

  end

end


def just_some_notes
  require 'open-uri'
  url = 'http://upload.wikimedia.org/wikipedia/commons/8/89/Robie_House.jpg'
  file = Tempfile.new(['temp','.jpg'])
  stringIo = open(url)
  file.binmode
  file.write stringIo.read
end
