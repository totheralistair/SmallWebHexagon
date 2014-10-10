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

  def dangerously_serialize_posts_history
    out = Array.new
    @thePosts.each {|req| out << req.serialized }
    out
  end

end

