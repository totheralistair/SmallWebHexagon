require 'rack'
require_relative '../src/smallwebhexagon'
require_relative '../src/ml_request'
require_relative '../src/html_from_templatefile'


class Smallwebhexagon_via_rack
# Hex adapter to Smallwebhexagon using Rack for web-type I/O
# is also tied to Erubis, which may need to be changed one day

  def initialize( viewsFolder ) #ugh on passing viewsFolder in :(
    @viewsFolder = viewsFolder
    @ml = Smallwebhexagon.new
  end


  def call(env) # hooks into the Rack Request chain
    request = Ml_RackRequest.new( env ) # hide the 'Rack'ness
    mlResult = @ml.handle( request )

    template_fn = @viewsFolder + mlResult[:out_action] + ".erb"
    page = htmlpage_from_templatefile( template_fn , binding )

    response = Rack::Response.new
    response.write( page )
    response.finish
  end

end

