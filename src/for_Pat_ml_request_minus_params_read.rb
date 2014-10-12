require 'rack'
require 'yaml'

#===== class Ml_request =========================

class Ml_request
  #nothing implemented at this level yet.
end


class Ml_RackRequest < Ml_request
# Warning about Rack::Request, it has two semi-undocumented strange things
# 1. three fields are StringIO, which do not serialize.
#    I have to turn them into strings temporarily to serialize,
#    and recreate them on loading from serializing
# 2. "params" modifies the request, adding the @params inst var
#    i.e. reading the params changes the request
#    This may only matter for testing or serialization.
#    but it is an undocumented side effect of reading params, so watch out.

  #note: this pile of accessors looks too complicated to me. Waiting for a simplification

  def initialize( env )
    @myRequest = Rack::Request.new( env )
#    @myRequest.params # calling params has "side effect" of changing the Request! :(.
    # better to do it now and save later surprises :-(
    # I commented that line out for Pat so the tests examine it properly
  end


  def env
    @myRequest.env
  end

  def incoming_contents
    @myRequest.params["MuffinContents"]
  end



  def self.deyamld serialized_request
    rreq = YAML::load StringIO.new( serialized_request )
    rreq.env["rack.input"] = StringIO.new(  rreq.env["rack.input"]  )
    rreq.env["rack.errors"] = StringIO.new(  rreq.env["rack.errors"]  )

    if rreq.env["rack.request.form_input"]
      rreq.env["rack.request.form_input"] = StringIO.new(  rreq.env["rack.request.form_input"]  )
    end
    rreq
  end


  def yamld
    rack_input = @myRequest.env["rack.input"]
    rack_errors = @myRequest.env["rack.errors"]
    form_input = @myRequest.env["rack.request.form_input"]

    @myRequest.env["rack.input"] = rack_input.string if rack_input.class == StringIO
    @myRequest.env["rack.errors"] = rack_errors.string if rack_errors.class == StringIO
    @myRequest.env["rack.request.form_input"] = form_input.string if form_input.class == StringIO

    out = YAML::dump(self)

    @myRequest.env["rack.input"] = rack_input
    @myRequest.env["rack.errors"] = rack_errors
    @myRequest.env["rack.request.form_input"] = form_input
    out
  end

end

