require 'rack'
require 'logger'

#===== class Ml_request =========================
# Ml_request defines the protocol for requests that
# can be sent in to Muffinland.
# Rack::Request to start with, but simpler ones for testing, possibly

class Ml_request

  #nothing implemented at this level yet.

end


#==================================
# a Rack::Request wrapper

class Ml_RackRequest < Ml_request
  #note: this pile of accessors looks too complicated to me. Waiting for a simplification

  def initialize( rack_request )
    @myRequest = rack_request
    @myRequest.env["Muffinland"] = { "Times" => {} }
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def theEnv ;  @myRequest.env ; end
  def theParams ;  @myRequest.params ; end
  def thePath ;  @myRequest.path ; end
  def theMuffinlandTags ;  theEnv["Muffinland"] ; end
  def theTimes ;  theMuffinlandTags["Times"] ; end


  def get?; @myRequest.get? ;  end
  def post?; @myRequest.post? || thePath=="/post"            ; end
  def add?;  theParams.has_key?("Add")    ; end
  def change?;  theParams.has_key?("Change") ; end
  def tag?;  theParams.has_key?("Tag")    ; end
  def addByFile?;  theParams.has_key?("Upload")    ; end
  def changeByFile?;  theParams.has_key?("ChangeByFile")    ; end
  def makeCollection?;  theParams.has_key?("Make Collection")    ; end
  def makeNonCollection?;  theParams.has_key?("Make Non-Collection")    ; end

  def command
    case
      when add?       then :add
      when change?    then :change
      when tag?       then :tag
      when addByFile? then :addByFile
      when changeByFile?    then :changeByFile
      when makeCollection?  then :makeCollection
      when makeNonCollection?  then :makeNonCollection
        else nil
    end
  end

  def make_collection? ;  theParams.has_key?("Collection") ? theParams["Collection"] : false ; end

  def name_from_path ;  thePath[ 1..thePath.size ] ;  end
  def id_from_path ;  id_from_name( name_from_path )     ;  end
  def incoming_muffin_name;  theParams["MuffinNumber"]   ;  end
  def incoming_muffin_id; n = incoming_muffin_name ; id_from_name( n ) ;  end
  def incoming_collector_name;  theParams["CollectorNumber"] ;  end
  def incoming_collector_id;  id_from_name( incoming_collector_name ) ;  end
  def incoming_contents;  theParams["MuffinContents"] ;  end

  # def has_legit_file? ;
  #  theParams["file"].has_key?(:tempfile)
  # end

  # Record Muffinland sh!t in the request

  def record_in_request( tag, valueString ) ;  theMuffinlandTags[tag] = valueString ;  end
  def record_time( tag ) ; t=Time.now;  theTimes[tag] = "#{t.to_f}";  end

  def record_muffin_id( id ) ;  record_in_request( "muffin_ID", id.to_s ) ;  end
  def record_arrival_time ;  record_time( "Arrived") ; end
  def record_completion_time ; record_time( "Completed");  end

  def arrival_time ; @times["Arrived"] ;  end
  def completion_time ;  @times["Completed"] ; end
  def execution_time ; t = completion_time.to_f - arrival_time.to_f ;end


  def id_from_name( name ) ;  number_or_nil(name) ;  end
  def number_or_nil( s ) # convert string to a number, nil if not a number
    i= s.to_i
    i.to_s == s ? i : nil
  end

end

