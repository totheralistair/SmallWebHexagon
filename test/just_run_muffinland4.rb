

require_relative '../src/Muffinland3b.rb'

Rack::Handler::WEBrick.run(
    Muffinland.new("../src/views/"),
    :Port => 8080
)

