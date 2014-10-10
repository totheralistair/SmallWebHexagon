require 'rack'
require 'yaml'

#===== class Ml_request =========================
# a Rack::Request wrapper
# # Ml_request defines the protocol for requests that
# can be sent in to Smallwebhexagon.
# Rack::Request to start with, but simpler ones for testing, possibly

class Ml_request
  #nothing implemented at this level yet.
end


class Ml_RackRequest < Ml_request
  #note: this pile of accessors looks too complicated to me. Waiting for a simplification

  def self.reconstitute_from serialized_request
    rreq = YAML::load StringIO.new( serialized_request )
    rreq.env["rack.input"] = StringIO.new(  rreq.env["rack.input"]  )
    rreq.env["rack.errors"] = StringIO.new(  rreq.env["rack.errors"]  )

     if rreq.env["rack.request.form_input"]
       rreq.env["rack.request.form_input"] = StringIO.new(  rreq.env["rack.request.form_input"]  )
     end
    rreq
  end



  def serialized
    rack_input = @myRequest.env["rack.input"]
    if rack_input.class == StringIO
      @myRequest.env["rack.input"] = rack_input.string
      changed_rack_input = true
    end

    rack_errors = @myRequest.env["rack.errors"]
    if rack_errors.class == StringIO
      @myRequest.env["rack.errors"] = rack_errors.string
      changed_rack_errors = true
    end

    form_input = @myRequest.env["rack.request.form_input"]
    if form_input.class == StringIO
      @myRequest.env["rack.request.form_input"] = form_input.string
      changed_form_input = true
    end

    out = YAML::dump(self)

    if changed_rack_input
      @myRequest.env["rack.input"] = rack_input
    end

    if changed_rack_errors
      @myRequest.env["rack.errors"] = rack_errors
    end

    if changed_form_input
      @myRequest.env["rack.request.form_input"] = form_input
    end

    out

  end




  def initialize( env )
    @myRequest = Rack::Request.new( env )
    @myRequest.params # calling params has "side effect" of changing the Request! :(.
                      # better to do it now and save later surprises :(
  end


  def env
    @myRequest.env
  end








  def get?; @myRequest.get? ;  end
  def post?; @myRequest.post? || thePath=="/post"            ; end
  def add?;  theParams.has_key?("Add")    ; end

  def command
    case
      when add?       then :add
        else nil
    end
  end

  def theParams ;
    puts "in theParams: " + @myRequest.inspect
    p @myRequest.GET
    p @myRequest.POST

    z=@myRequest.params ;
    puts "done theParams: " + @myRequest.inspect
    z
  end
  def thePath ;  @myRequest.path ; end

  def name_from_path ;  thePath[ 1..thePath.size ] ;  end
  def id_from_path ;  id_from_name( name_from_path )     ;  end
  def id_from_name( name ) ;  number_or_nil(name) ;  end
  def number_or_nil( s ) # convert string to a number, nil if not a number
    i= s.to_i
    i.to_s == s ? i : nil
  end

  def incoming_muffin_name;  theParams["MuffinNumber"]   ;  end
  def incoming_muffin_id; n = incoming_muffin_name ; id_from_name( n ) ;  end
  def incoming_contents;
    puts "in incoming_contents: " + self.inspect

    f=theParams["MuffinContents"] ;
    puts "f:" + f.inspect

    puts "ending incoming_contents: " + self.inspect
    f
  end


end

