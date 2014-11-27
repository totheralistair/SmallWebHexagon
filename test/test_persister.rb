require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
require 'fileutils'
require 'yaml'
require_relative '../src/smallwebhexagon.rb'
require_relative '../src/smallwebhexagon_via_rack.rb'
require_relative '../src/ml_request'
require_relative '../src/persisters'
require_relative '../test/utilities_for_tests'


class TestRequests < Test::Unit::TestCase
  attr_accessor :app


  def test_01_nul_persister_does_nothing_or_just_prints
    p __method__

    @app = Smallwebhexagon.new  Nul_persister.new
    r0 = new_ml_request "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" }
    app.handle r0
  end

  def test_02_file_persister_adds_to_file
    p __method__

    out_fn = 'mlhistory.txt'
    @app = Smallwebhexagon.new File_persister.new  out_fn

    app.handle new_ml_request( "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    File.readlines(out_fn).should == File.readlines('mlhistory_reference1.txt')

    app.handle new_ml_request( "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    File.readlines(out_fn).should == File.readlines('mlhistory_reference2.txt')
  end


end


