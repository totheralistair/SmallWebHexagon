

require_relative '../src/Muffinland3b.rb'

Rack::Handler::WEBrick.run(
    Muffinland.new,
    :Port => 8080
)

