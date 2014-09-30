# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# ideas: email, DTO test,

require 'logger'
require_relative '../src/ml_responses' # the API output defined for Muffinland
require_relative '../src/baker'
require_relative '../src/muffin'
require_relative '../src/historian'
require_relative '../src/ml_request'


class Muffinland
# Muffinland knows global policies and environment, not histories and private things.

  def initialize
    @theHistorian = Historian.new # knows the history of requests
    @theBaker = Baker.new         # knows the muffins
    @log = Logger.new(STDOUT); @log.level = Logger::INFO
  end

#===== Visitor Edge of the Hexagon =====
# invoke 'handle(request)' directly.
# input: any class that supports the Ml_request interface
# output: a hash with all the data produced for consumption

  def handle( request ) # note: all 'handle's return 'ml_response' in a chain

    request.record_arrival_time
    ml_response =
        case
          when request.get? then handle_get_muffin(request)
          when request.post? then handle_post(request)
        end
    request.record_completion_time
    ml_response
  end


#===== The commands to be handled (and the handling)=======

  def handle_get_muffin( request )
    id = request.name_from_path=="" ? @theBaker.default_muffin_id : request.id_from_path
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

    # there is for sure a way to put all the rest of this file into a lookup table; but I don't know how yet
    # like { [command, execution method, happy output, failure output ] }
    # eg { :add [handle_add_muffin(), add_muffin_from_text(), ml_response_for_GET_muffin(), ml_response_for_404_basic()] }
    # so for now it's just all spelled out longhand.

    ml_response = case request.command
                    when :add          then  handle_add_muffin(request)
                    when :addByFile    then  handle_add_by_file(request)
                    when :change       then  handle_change_muffin(request)
                    when :changeByFile then  handle_change_by_file(request)
                    when :tag          then  handle_tag_muffin(request)
                    when :makeCollection then  handle_makeCollection(request)
                    when :makeNonCollection then  handle_makeNonCollection(request)
                    when :upload       then handle_add_by_file(request)
                    else              handle_unknown_post(request)
                  end
  end

  def handle_unknown_post( request )
    @log.info "DOIN NUTHNG. not a recognized command"
    ml_response_for_UnregisteredCommand
  end

  def handle_add_muffin( request )

    m = @theBaker.add_muffin_from_text(request)
    m ? ml_response_for_GET_muffin( m ) :
        ml_response_for_404_basic( request )
  end

  def handle_add_by_file( request )
    m = @theBaker.add_muffin_from_file(request)
    m ? ml_response_for_GET_muffin( m ) :
        ml_response_for_400_no_file_provided( request )
  end

  def handle_makeCollection( request )
    m = @theBaker.make_collection(request)
    m ? ml_response_for_GET_muffin( m ) :
        ml_response_for_404_basic( request )
  end

  def handle_makeNonCollection( request )
    m = @theBaker.make_noncollection(request)
    m ? ml_response_for_GET_muffin( m ) :
        ml_response_for_404_basic( request )
  end

  def handle_change_muffin( request )
    m = @theBaker.change_muffin( request )
    m ? ml_response_for_GET_muffin( m ) :
        ml_response_for_404_basic( request )
  end

  def handle_change_by_file( request )
    m = @theBaker.change_muffin_from_file( request )
    m ? ml_response_for_GET_muffin( m ) :
        ml_response_for_400_no_file_provided( request ) # not strictly correct, i suspect
  end

  def handle_tag_muffin( request )
    m = @theBaker.tag_muffin_per_request( request )
    m ? ml_response_for_GET_muffin( m ) :
        ml_response_for_404_basic( request ) # not correct, cuz failure may be collector id
  end


end

