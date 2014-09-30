

#===== class Muffin ==============
# knows or can produce everything about itself. Knows nothing else

class Muffin

  def initialize( id, raw_contents, content_type="text/plain")
    @myID = id
    new_contents( raw_contents, content_type )
  end

  def content_type ;  @myContent_type ;  end
  def id  ;  @myID  ;  end
  def raw ;  @myRaw ;  end

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
