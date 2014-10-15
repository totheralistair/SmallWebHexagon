require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require 'fileutils'
require 'yaml'
require_relative '../src/smallwebhexagon.rb'
require_relative '../src/smallwebhexagon_via_rack.rb'
require_relative '../src/ml_request'
require_relative '../test/utilities_for_tests'


class TestRequests < Test::Unit::TestCase
  attr_accessor :app

  #------ the tests ---------

  def test_z_runs_via_Rack_adapter # just check hexagon integrity, not a data check
    p __method__

    viewsFolder = "../src/views/"
    @app = Smallwebhexagon_via_rack.new( Smallwebhexagon.new( Nul_persister.new ), viewsFolder )

    request_via_rack_adapter_without_server( app, "GET", '/a?b=c', "d=e").body.
        should == page_from_template( viewsFolder + "EmptyDB.erb" , binding )
  end


  def test_00_emptyDB_is_special_case
    p __method__

    @app = Smallwebhexagon.new( Nul_persister.new )

    sending_expect "GET", '/aaa', {} ,
                   {
                       out_action:  "EmptyDB"
                   }
  end


  def test_01_posts_return_contents
    p __method__

    @app = Smallwebhexagon.new( Nul_persister.new )

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
    p __method__

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    y0 = r0.to_yaml

    r1 = Ml_RackRequest::from_yaml( y0 )
    y1 = r1.to_yaml

    y0.should == y1
  end



  def test_03_can_reload_history_from_array_and_continue
    p __method__

    @app = Smallwebhexagon.new( Nul_persister.new )

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    app.dangerously_restart_with_history [ r0 ]

    r1 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"banaba" })
    app.handle r1

    app.dangerously_all_posts.should == [ r0, r1 ]
  end




  def test_04_can_run_history_to_from_strings_and_files
    p __method__

    @app = Smallwebhexagon.new( Nul_persister.new )

    # 1st fake a history in a file:
    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" })
    array_to_file( [ r0.to_yaml ], history_in_file='mlhistory.txt' )
    dangerously_replace_history_from_stream( app, File.open( history_in_file) )

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
    history_in_string = array_into_string ( history << r2.to_yaml )
    dangerously_replace_history_from_stream( app, StringIO.new( history_in_string) )

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


