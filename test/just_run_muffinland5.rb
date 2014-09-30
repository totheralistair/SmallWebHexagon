

require_relative '../src/muffinland5.rb'

Rack::Handler::WEBrick.run(
    Muffinland.new("../src/views/"),
    :Port => 8080
)

