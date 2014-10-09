
class MuffinTin
# known only by the Baker, the MuffinTin
# knows what muffin ids are made from. shhhh top secret.
# The Baker adds, finds, modifies muffins via the MuffinTin

  def initialize
    @muffins = Array.new
  end

  def at( id ) ; @muffins[id]  ;  end
  def next_id ;  @muffins.size ;  end
  def default_muffin_id ; 0 ; end # let default page be page zero. Not sure this belongs here.

  def empty?
    @muffins.empty?
  end

  def is_legit?( id )
    (id.is_a? Integer) && ( id > -1 ) && ( id < @muffins.size )
  end

  def add_raw( content, content_type="text/plain" )  # muffinTin not allowed to know what contents are.
    m = Muffin.new( next_id, content, content_type )
    @muffins << m
    m
  end


end

#===== class Baker ==============
# knows the handlings of muffins.

class Baker

  def initialize
    @muffinTin = MuffinTin.new
  end

  # def dangerously_new_muffintin
  #   @muffinTin = MuffinTin.new
  # end



  def muffin_at(id) ;  @muffinTin.at( id ) ;  end
  def is_legit?(id) ;  @muffinTin.is_legit?(id) ;  end
  def default_muffin_id ; @muffinTin.default_muffin_id ; end

  def aint_got_no_muffins_yo?
    @muffinTin.empty?
  end

  def muffin_at_id( m_id )
    muffin_at(m_id) if is_legit?(m_id)
  end


  def add_muffin_from_text( request ) # BAD. something wrong w this on Binary input
    m = @muffinTin.add_raw( request.incoming_contents )
  end

end


