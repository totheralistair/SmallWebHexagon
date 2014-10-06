require 'rack'

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

  def initialize( rack_request )
    @myRequest = rack_request
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

  def theParams ;  @myRequest.params ; end
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
  def incoming_contents;  theParams["MuffinContents"] ;  end


end

