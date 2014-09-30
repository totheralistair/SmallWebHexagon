# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
#
require 'rack'
require 'erb'
require 'erubis'

class Muffinland
  attr :viewsFolder

  def initialize(viewsFolder)
    @viewsFolder = viewsFolder
  end

  def call(env)
    request  = Rack::Request.new(env)
    if request.get? then out = handle_get(request); end
    if request.post? then out = handle_post(request); end
    out
  end
end

def page_from_template( fn )
  Erubis::Eruby.new(File.open( fn, 'r').read)
end


def handle_get( request )
  path = request.path
  params = request.params
  case path
    when "/login"
      handle_login( path, params )
    else
      handle_otherGET( path, params )
  end
end

def handle_login( path, params )
  puts "in Login"
  "login"
  response = Rack::Response.new
  dynamic_page = page_from_template( @viewsFolder + "simpleDataInput.erb" )
  response.write dynamic_page.result(binding())
  response.finish
end

def handle_otherGET( path, params )
  response = Rack::Response.new
  dynamic_page = page_from_template( @viewsFolder + "simpleGET.erb" )
  response.write dynamic_page.result(binding())
  response.finish
end


#===================================================
def handle_post( request ) # expect Rack::Request, return Rack::Response
  @myPosts ||= Array.new
  @myPosts.push(request)

  path = request.path
  params = request.params

  response = Rack::Response.new
  dynamic_page = page_from_template( @viewsFolder + "simplePOST.erb" )
  response.write dynamic_page.result(binding())
  response.finish
end




