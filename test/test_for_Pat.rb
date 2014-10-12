require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require 'fileutils'
require 'yaml'
require_relative '../src/for_Pat_ml_request_minus_params_read.rb'
#Test::Unit::TestCase.include RSpec::Matchers


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
    s1.should == s0   # except it doesn't

  end


  def test_03_forcing_params_read_solves_serialization_problem

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" })

    p r0.incoming_contents

    s0 = r0.yamld

    whatever = r0.incoming_contents

    s1 = r0.yamld
    s1.should == s0   # shouldn't have different behavior than test_02

  end


end

