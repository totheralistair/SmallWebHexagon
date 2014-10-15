require 'logger'
require_relative '../src/baker'


class Historian # knows the history of what has happened, all Posts

def initialize persister
    @thePersister = persister
    @thePosts = Array.new
  end

  def no_history_to_report?;  @thePosts.size == 0 ;  end

  def dangerously_all_posts ;  @thePosts ;  end  #yep, dangerous. remove eventually

  def add_request( request )
    @thePosts << request
    @thePersister.handle_new_post request
  end

end

