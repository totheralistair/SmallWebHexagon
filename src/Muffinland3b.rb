# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends

require 'rack'
require 'erb'
require 'sinatra'
require 'erubis'

class Muffinland < Sinatra::Base
  def call(env)
    request  = Rack::Request.new(env)
    if request.get? then out = handle_get(request); end
    if request.post? then out = handle_post(request); end
    out
  end
end

def construct_page_from_template( pathToViews, viewfilename )
  fn = pathToViews + viewfilename
  Erubis::Eruby.new(File.open( fn, 'r').read)
end


def handle_get( request )
  params = request.params
  path = request.path

  response = Rack::Response.new
  response['Content-Type'] = 'text/html'

  pathToViews = "../src/views/"
  viewfilename = "simpleGET.erb"
  eruby = Erubis::Eruby.new(File.open( pathToViews+viewfilename, 'r').read)
  response.write eruby.result(binding())

  response.finish

end

def outFor(path, params)
  puts path
  case path
    when "/login"
      handle_login params
    when "/aaa"
      "aaa"
    else
      "whatever and :#{params}:"
  end
end




#===================================================
def handle_post( request ) # expect Rack::Request, return Rack::Response
  @myPosts ||= Array.new
  @myPosts.push(request)

  params = request.params
  pathinfo = request.path_info

  response = Rack::Response.new
  response['Content-Type'] = 'text/html'
  response.write "Got that POST, baby. "
  response.write "Page requested = #{pathinfo}. "
  response.write "Params = #{params}. "
  response.finish
end




