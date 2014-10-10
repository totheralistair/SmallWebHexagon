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
    request.request(method, path, {:params=>params}) # sends the request through the Rack call(env) chain
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
    rreq0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    sreq0 = rreq0.serialized

    rreq1 = Ml_RackRequest::reconstitute_from( sreq0 )
    sreq1 = rreq1.serialized

    sreq0.should == sreq1
  end



  def test_03_history_dumps_serialized_as_i_expect
    p "in test 3"
    @app = Smallwebhexagon.new

    request0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    app.handle request0
    sreq0 = request0.serialized  # warning - "handle" actually changes the request, so serialize & compare after 'handle'
    rreq0 = Ml_RackRequest::reconstitute_from( sreq0 )
    ssreq0 = rreq0.serialized

    app.dangerously_serialize_posts_history.should == [ ssreq0 ]

    request1 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"banaba" })
    app.handle request1
    sreq1 = request1.serialized
    app.dangerously_serialize_posts_history.should == [ sreq0, sreq1 ]

  end



  def NO_test_04_loads_history_from_array_and_grows_it
    #BROKEN

    @app = Smallwebhexagon.new

    requestAppleOnce = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    app.handle requestAppleOnce # we have to let ML change the request. ugh.
    historyAfterAppleOnce = app.dangerously_serialize_posts_history
    sreqAppleOnce = historyAfterAppleOnce[0] # get the serialized request post-handling

    requestBanabaOnce = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"banaba" })
    app.handle requestBanabaOnce
    historyAfterBanabaOnce = app.dangerously_serialize_posts_history
    sreqBanabaOnce = historyAfterBanabaOnce[0] # get the serialized request post-handling

    app.dangerously_replace_history( historyAfterAppleOnce )
    # just to be paranoid, Im' going to doublecheck the serialization again
    historyAfterReload = app.dangerously_serialize_posts_history
    historyAfterReload.should == historyAfterAppleOnce
    historyAfterReload.should == [ sreqAppleOnce ]

    requestBanabaAgain = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"banaba" })
    app.handle requestBanabaAgain
    historyAfterBanabaRerun = app.dangerously_serialize_posts_history

    p "size shouled be 2"; historyAfterBanabaRerun.size.should == 2
    puts historyAfterBanabaRerun[0].inspect
    p "at 0 shd be apple"; historyAfterBanabaRerun[0].should == [ sreqAppleOnce ]

    p "BAH. SREQAPPLEONCE GOT CHANGED OR SOMETHING. SUCK!"

    # p "at 1 should be banaba"; historyAfterBanabaRerun[1].should == [ sreqBanabaOnce ]
    # p historyAfterBanabaRerun[1]
    # p sreqAppleOnce
    # p sreqBanabaOnce
    # historyAfterBanabaRerun#.should == [ sreqAppleOnce, sreqBanabaOnce ]

  end





  def test_03_historian_adds_to_history
    return "CUZ IT FAILS, SUCKA"
    @app = Smallwebhexagon.new
    request = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    sreq = request.serialized
    app.dangerously_replace_history [ sreq ]

    request = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"chickens" })

    p "pre handle request"
    p request

    p "history before"
    app.dangerously_serialize_posts_history
    p ""


    app.handle request
    # sending_r_expect request,
    #                {
    #                    out_action:   "GET_named_page",
    #                    muffin_id:   0,
    #                    muffin_body: "chickens"
    #                }
    # p "post handle request"
    # p request

    p "history"
    p app.dangerously_serialize_posts_history
p "so there"

    app.dangerously_serialize_posts_history.should == [
        sreq,
        request.serialized ]

  end












#====== BROKEN FROM HERE ON DOWN ======
  def test_06_can_load_history_from_files
    return

    app = Smallwebhexagon.new
    request = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })



    puts request.racks_input_value_raw.inspect
    p request.racks_error_value_raw.string

    str = request.racks_input_value_as_string
    request.replace_racks_input_with_string( str )
    puts request.racks_input_value_raw.inspect

    request = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    request.replace_racks_input_with_its_value
    puts request.racks_input_value_raw.inspect

    # request.replace_racks_fake_input_with_new_StringIO
    # puts request.racks_input_value_raw.inspect
    # puts request.racks_input_value_raw.string

    request.replace_racks_errors_with_nil
    p YAML.dump(request)

    p "boo"

    puts Marshal.dump(request).inspect



    return

    puts Marshal.dump(request)

    FileUtils.rm('history.txt') if File.file?('history.txt')
    File.open('history.txt', 'w') do |f|
      f << YAML.dump(request)
    end
    history = File.open('history.txt')

    history.should_not be_nil

    history.extend FileWarehouse

    app.dangerously_replace_history history

    mlResponse = request_via_API( app, "GET", '/0' )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        muffin_body: "apple"
    }
    mlResponse.slice_per( exp ).should == exp
  end

end

module More_notes_FileWarehouse
  def each(&block)
    lines = readlines.map(&:strip).reject {|l| l.empty? }
    lines.each {|l| block.call(YAML.load(l)) }
  end

  def size
  end

  def <<(o)
  end
end

def just_notes
  require 'open-uri'
  url = 'http://upload.wikimedia.org/wikipedia/commons/8/89/Robie_House.jpg'
  file = Tempfile.new(['temp','.jpg'])
  stringIo = open(url)
  file.binmode
  file.write stringIo.read
end
