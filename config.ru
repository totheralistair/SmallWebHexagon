# Here is how to go through Rackup
require './src/muffinland_via_rack'
run Muffinland_via_rack.new("./src/views/")



# Here is how to go through Rack directly
# require_relative './src/muffinland_via_rack.rb'
# Rack::Handler::WEBrick.run(
#     Muffinland_via_rack.new("./src/views/"),
#     :Port => 9292
# )


# As reminder: here is the simplest rack program
#run lambda { |env| [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello 3 lambda!\n")] }

