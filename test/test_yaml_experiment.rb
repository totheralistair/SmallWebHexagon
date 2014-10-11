require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require 'fileutils'
require 'yaml'
require_relative '../src/for_Pat_ml_request_minus_params_read.rb'
#Test::Unit::TestCase.include RSpec::Matchers
require 'stringio'


class TestRequests < Test::Unit::TestCase

  def new_ml_request method, path, params={}
    Ml_RackRequest.new  Rack::MockRequest.env_for( path, {:method => method, :params=>params} )
  end


  def test_01_requests_serialize_and_reconstitute_back_and_forth

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"chickens" })
    s0 = r0.serialized

    r1 = Ml_RackRequest::reconstitute_from( s0 )
    s1 = r1.serialized

    s0.should == s1
  end



  def test_02_reading_params_changes_serialization

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"more chickens" })
    s0 = r0.serialized

    p r0.incoming_contents
    whatever = r0.incoming_contents

    s1 = r0.serialized
    s1.should_not == s0   # except it doesn't

  end


  def test_03_forcing_params_read_solves_serialization_problem

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" })

    p r0.incoming_contents

    s0 = r0.serialized

    whatever = r0.incoming_contents

    s1 = r0.serialized
    s1.should == s0   # shouldn't have different behavior than test_02
  end

  def test_04_file_also_works

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" })
    whatever = r0.incoming_contents
    s0 = r0.serialized


    r1 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"more chickens" })
    whatever = r1.incoming_contents
    s1 = r1.serialized

    h0 = [ s0, s1 ]

    fn = 'mlhistory.txt'
    FileUtils.rm( fn ) if File.file?( fn )
    File.open( fn, 'w') do |f|
      f << s0
      f << s1
    end

    openstream = File.open( fn )
    history =YAML::load_stream( openstream )
    history[0].serialized.should == s0
    history[1].serialized.should == s1
    p s1.class

    #----------------

    str = StringIO.new %{This is a test of a string as a file. \r\n
                     And this could be another line in the file}

    p str.gets # => "This is a test of a string as a file. \r\n"


    strio = StringIO.open do |sio|
      sio<< "boo"
      sio.write s1
      sio
    end
    strio=strio.reopen
    p strio.class
    p strio.gets

    history =YAML::load_stream( strio.reopen )
    history[0].serialized.should == s0
    history[1].serialized.should == s1

  end

end

