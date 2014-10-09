require 'logger'
require_relative '../src/baker'


#===== class Historian ==============
# knows the history of what has happened, all Posts

class Historian

  def initialize
    @thePosts = Array.new
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def no_history_to_report?;  @thePosts.size == 0 ;  end
  def dangerously_all_posts ;  @thePosts ;  end  #yep, dangerous. remove eventually


  def add_request( request )
    @thePosts << request
  end

  def dangerously_replace_history( aBaker, serializedRequests )
    # I think this is incorrect, as it only replaces muffins, it should
    # "quietly" re-handle the POSTs, without output.
    initialize
    serializedRequests.each {|sreq|
      rreq = Ml_RackRequest::reconstitute_from sreq
      aBaker.add_muffin_from_text rreq
      self.add_request rreq
    }
  end

  def dangerously_dump_history
    out = Array.new
    @thePosts.each {|rreq|
      out << rreq.serialized
    }
    out
  end

end

