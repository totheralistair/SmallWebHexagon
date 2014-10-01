# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# ideas: email, DTO test,

require_relative '../src/ml_responses' # the API output defined for Muffinland
require_relative '../src/baker'
require_relative '../src/muffin'
require_relative '../src/historian'


class Muffinland
# Muffinland knows global policies and environment, not histories and private things.

  def initialize
    @theHistorian = Historian.new # knows the history of requests
    @theBaker = Baker.new         # knows the muffins
  end

#===== Visitor Edge of the Hexagon =====
# invoke 'handle(request)' directly.
# input: any class that supports the Ml_request interface
# output: a hash with all the data produced for consumption

  def handle( request ) # note: all 'handle's return 'ml_response' in a chain

    ml_response =
        case
          when request.get? then handle_get_muffin(request)
          when request.post? then handle_post(request)
        end
  end



  def handle_get_muffin( request )
    id = request.name_from_path=="" ?
        @theBaker.default_muffin_id :
        request.id_from_path

    m = @theBaker.muffin_at_id( id )

    ml_response =
        case
          when @theHistorian.no_history_to_report?
            ml_response_for_EmptyDB
          when m
            ml_response_for_GET_muffin( m )
          else
            ml_response_for_404_basic( request )
        end
  end


  def handle_post( request )
    @theHistorian.add_request( request )
    ml_response =     handle_add_muffin(request)
  end


  def handle_add_muffin( request )
    m = @theBaker.add_muffin_from_text(request)
    ml_response_for_GET_muffin( m )
  end

end

