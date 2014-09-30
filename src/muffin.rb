require 'logger'

#===== class Muffin ==============
# knows or can produce everything about itself. Knows nothing else

class Muffin

  def initialize( id, raw_contents, content_type="text/plain")
    @myID = id
    @belongs_to_collections = Set.new
    @isCollection = false
    @collects_muffins = Set.new
    new_contents( raw_contents, content_type )
  end

  def add_tag(t) ;  @belongs_to_collections << t;  self ; end
  def belongs_to_ids ; s = @belongs_to_collections.collect{ |m| m.id}; s; end
  def collection? ; @isCollection ; end
  def collects_ids ; s = @collects_muffins.collect{ |m| m.id} ;  s ;  end
  def collect_muffin ( m ) ; @collects_muffins << m ; end
  def content_type ;  @myContent_type ;  end
  def id  ;  @myID  ;  end
  def raw ;  @myRaw ;  end

  # Note! these do not change the collection contents!! By design (I think)
  # so you can make a collection a non-collection and it still has the collction
  # reverse it, and the collected set "reappears". I /think/ this is a good idea.?
  def make_collection ;  @isCollection=true; end
  def make_noncollection ;  @isCollection=false;  end

  def add_to_collection ( c )
    return nil if !c.collection?
    @belongs_to_collections << c
    c.collect_muffin( self )
  end

  def new_contents( raw_contents, content_type="text/plain" )
    @myContent_type = content_type
    @myRaw = raw_contents
    self
  end

  def for_viewing
    case
      when content_type == 'text/plain'
        raw
      when content_type == 'image/png' || content_type == 'image/jpg'
        '<img src="data:image/png;base64,' + Base64.encode64(raw) + '" /> '
      else
        "no content, nothing there; content_type=#{content_type.inspect}"
    end

  end

end
