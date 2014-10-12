require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require 'fileutils'
require 'yaml'
require_relative '../src/smallwebhexagon.rb'
require_relative '../src/smallwebhexagon_via_rack.rb'
require_relative '../src/ml_request'
#Test::Unit::TestCase.include RSpec::Matchers not needed at the moment


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
    actual = app.handle ml_req
    hash_submatch actual, expectedResult
  end


  def hash_submatch( fatHash, thinHash )
    slice_per( fatHash, thinHash ).should == thinHash
  end

  # {:a=>1, :b=>2, :c=>3}.slice_per({:b=y, :c=>z}) returns {:b=>2, :c=>3}
  def slice_per( fatHash, thinHash )
    thinHash.inject({}) { |slice, (k,v) | slice[k] = fatHash[k] ; slice }
  end


  def request_via_rack_adapter_without_server( app, method, path, params={} ) # app should be Muffinland_via_rack
    request = Rack::MockRequest.new(app)
    request.request(method, path, {:params=>params}) # sends the r0 through the Rack call(env) chain
  end

  def page_from_template( fn, binding )
    pageTemplate = Erubis::Eruby.new(File.open( fn, 'r').read)
    pageTemplate.result(binding)
  end

  #===============

  def deyaml_requests_from_stream(stream)
    requests = YAML::load_documents( stream )
    requests.each {|r| r.clean_deyamld }
  end

  def array_to_file( array_of_stuff, fn )
    FileUtils.rm( fn ) if File.file?( fn )
    File.open( fn, 'w') do |f|
      array_of_stuff.each {|y| f<<y}
    end
  end

  def array_into_string( array_of_yamlds )
    array_of_yamlds.inject("") {|out, y| out << y}
  end


  def stream_match_yamlds( stream_of_yamlds, array_of_yamlds )
    new_history =deyaml_requests_from_stream( stream_of_yamlds )
    array_of_yamlds.each_with_index { |y, i|
      new_history[i].yamld.should == y
    }
  end


  def adapter_dangerously_replace_history_from_stream( app, stream )
    requests = deyaml_requests_from_stream(stream)
    requests.each {|r| r.clean_deyamld }
    app.dangerously_replace_history requests
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
    p "in test test_01_posts_return_contents"
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
    p "in test test_02_requests_serialize_and_reconstitute_back_and_forth"
    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    y0 = r0.yamld

    r1 = Ml_RackRequest::deyamld( y0 )
    y1 = r1.yamld

    y0.should == y1
  end



  def test_03_can_reload_history_from_array_and_continue
    p "in test test_03_can_reload_history_from_array_and_continue"
    @app = Smallwebhexagon.new

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    app.dangerously_replace_history [ r0 ]

    r1 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"banaba" })
    app.handle r1

    app.dangerously_all_posts.should == [ r0, r1 ]
  end




  def test_04_can_run_history_to_from_strings_and_files
    p "in test test_04_can_run_history_to_from_strings_and_files"
    @app = Smallwebhexagon.new

    # 1st fake a history in a file:
    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" })
    array_to_file( [ r0.yamld ], history_in_file='mlhistory.txt' )
    adapter_dangerously_replace_history_from_stream( app, File.open( history_in_file) )

    # see if that works:
    sending_expect "GET", '/0', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   0,
                       muffin_body: "less chickens"
                   }

    # then add to the history in the ordinary way, make sure that still works.
    sending_expect 'POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"more chickens" } ,
                     {
                         out_action:   "GET_named_page",
                         muffin_id:   1,
                         muffin_body: "more chickens"
                     }

    # finally, add to the history using faked-up string / StringIO, see if that works:
    history = app.dangerously_all_posts_yamld
    r2 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"end of chickens" })
    history_in_string = array_into_string ( history << r2.yamld )
    adapter_dangerously_replace_history_from_stream( app, StringIO.new( history_in_string) )

    sending_expect "GET", '/1', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   1,
                       muffin_body: "more chickens"
                   }

    sending_expect "GET", '/2', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   2,
                       muffin_body: "end of chickens"
                   }

    sending_expect "GET", '/3', {},
                   {
                       out_action:   "404"
                   }
    # if that all works, loading/unloading/faking history w arrays/strings/files work :-)
  end

end


