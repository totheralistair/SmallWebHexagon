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



#===============

def deyaml_requests_from_stream(stream)
  requests = YAML::load_documents( stream ) { |req|
    req.clean_from_yaml
  }
  # requests = YAML::load_documents( stream )
  requests.each {|r| r.clean_from_yaml }
end

def prepare_for_file( fn )
  FileUtils.rm( fn ) if File.file?( fn )
end

def array_to_file( array_of_stuff, fn )
  prepare_for_file( fn )
  # FileUtils.rm( fn ) if File.file?( fn )
  File.open( fn, 'w') do |f|
    array_of_stuff.each {|y| f<<y}
  end
end

def array_into_string( array_of_yamlds )
  array_of_yamlds.inject("") {|out, y| out << y}
end


def dangerously_replace_history_from_stream( app, stream )
  requests = deyaml_requests_from_stream(stream)
  requests.each {|r| r.clean_from_yaml }
  app.dangerously_restart_with_history requests
end


def request_via_rack_adapter_without_server( app, method, path, params={} ) # app should be Muffinland_via_rack
  request = Rack::MockRequest.new(app)
  request.request(method, path, {:params=>params}) # sends the req through the Rack call(env) chain
end

def page_from_template( fn, binding )
  pageTemplate = Erubis::Eruby.new(File.open( fn, 'r').read)
  pageTemplate.result(binding)
end


