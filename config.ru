# Here is how to go through Rackup
require './src/smallwebhexagon_via_rack'
require './src/persisters'

run Smallwebhexagon_via_rack.new(  Smallwebhexagon.new(Nul_persister.new),"./src/views/" )



# Here is how to go through Rack directly
# require_relative './src/smallwebhexagon_via_rack.rb'
# Rack::Handler::WEBrick.run(
#     Muffinland_via_rack.new("./src/views/"),
#     :Port => 9292
# )


# As reminder: here is the simplest rack program
#run lambda { |env| [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello 3 lambda!\n")] }

