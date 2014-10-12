require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require 'fileutils'
require 'yaml'
require_relative '../src/for_Pat_ml_request_minus_params_read.rb'
require 'stringio'


class TestRequests < Test::Unit::TestCase

  def new_ml_request method, path, params={}
    Ml_RackRequest.new  Rack::MockRequest.env_for( path, {:method => method, :params=>params} )
  end


  def test_01_requests_serialize_and_reconstitute_back_and_forth

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"chickens" })
    s0 = r0.yamld

    r1 = Ml_RackRequest::deyamld( s0 )
    s1 = r1.yamld

    s0.should == s1
  end



  def test_02_reading_params_changes_serialization

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"more chickens" })
    s0 = r0.yamld

    p r0.incoming_contents
    whatever = r0.incoming_contents

    s1 = r0.yamld
    s1.should_not == s0   # except it doesn't

  end


  def test_03_forcing_params_read_solves_serialization_problem

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" })

    p r0.incoming_contents

    s0 = r0.yamld

    whatever = r0.incoming_contents

    s1 = r0.yamld
    s1.should == s0   # shouldn't have different behavior than test_02
  end



  def test_04_can_serialize_to_file_and_to_stringio
    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" });r0.incoming_contents
    r1 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"more chickens" });r1.incoming_contents
    yamls = [r0.yamld, r1.yamld]

    send_to_file( file_history='mlhistory.txt', yamls )
    string_history = send_to_string( yamls )

    histories_should_match( File.open( file_history ), yamls )
    histories_should_match( StringIO.new(string_history), yamls )
  end


end
#===============

def send_to_file( fn, array_of_yamlds )
  fn = 'mlhistory.txt'
  FileUtils.rm( fn ) if File.file?( fn )
  File.open( fn, 'w') do |f|
    array_of_yamlds.each {|y| f<<y}
  end
end

def send_to_string( array_of_yamlds )
  array_of_yamlds.inject("") {|out, y| out << y}
end


def deyaml(stream)
  YAML::load_documents( stream )
end

def     histories_should_match( stream, array_of_yamlds )
  new_history =deyaml( stream )
  array_of_yamlds.each_with_index { |y, i|
    new_history[i].yamld.should == y
  }
end

