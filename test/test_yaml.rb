require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require 'fileutils'
require 'yaml'
require_relative '../src/ml_request.rb'
require 'stringio'
require_relative '../test/utilities_for_tests'


class TestRequests < Test::Unit::TestCase

  # def new_ml_request method, path, params={}
  #   Ml_RackRequest.new  Rack::MockRequest.env_for( path, {:method => method, :params=>params} )
  # end
  #

  def test_01_requests_serialize_and_reconstitute_back_and_forth

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"chickens" })
    s0 = r0.to_yaml

    r1 = Ml_RackRequest::from_yaml s0
    s1 = r1.to_yaml

    s0.should == s1
  end



  def test_02_reading_params_changes_serialization
    #the updated ml_request fixes the problem, so no workaround is needed

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"more chickens" })
    s0 = r0.to_yaml

    blarging_read = r0.incoming_contents

    s1 = r0.to_yaml
    s1.should == s0   # does now, cuz of the fixed-up ml_request

  end


  def test_03_forcing_params_read_solves_serialization_problem

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" })

    s0 = r0.to_yaml

    blarging_read = r0.incoming_contents

    s1 = r0.to_yaml
    s1.should == s0   # shouldn't have different behavior than test_02
  end



  def test_04_can_serialize_to_file_and_to_stringio
    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" })
    r1 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"more chickens" })
    yamls = [r0.to_yaml, r1.to_yaml]

    array_to_file( yamls,file_history='mlhistory.txt' )
    string_history = array_into_string( yamls )

    stream_match_yamlds( File.open( file_history ), yamls )
    stream_match_yamlds( StringIO.new(string_history), yamls )
  end


end
#===============

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
  objects_from_yamls = YAML::load_documents  stream_of_yamlds
  array_of_yamlds.each_with_index { |aYaml, i|
    objects_from_yamls[i].to_yaml.should == aYaml
  }
end

