# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends

require 'rack'

class Muffinland

  def call(env)
    request  = Rack::Request.new(env)
    if request.get? then
      out = handle_get(request); end
    if request.post? then
      out = handle_post(request); end
    out
  end
end

def handle_get( request )
  params = request.params
  pathinfo = request.path_info

  response = Rack::Response.new
  response['Content-Type'] = 'text/html'
  response.write "Nice GET there. "
  response.write "Page requested = #{pathinfo}. "
  response.write "Params = #{params}. "
  response.write "Bests. Alistair."
  response.finish
end

def handle_post( request ) # expect Rack::Request, return Rack::Response
  params = request.params
  pathinfo = request.path_info

  response = Rack::Response.new
  response['Content-Type'] = 'text/html'
  response.write "Got that POST, baby. "
  response.write "Page requested = #{pathinfo}. "
  response.write "Params = #{params}. "
  response.finish
end






