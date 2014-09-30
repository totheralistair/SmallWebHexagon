require 'logger'
require 'set'
require 'base64'


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


  def is_legit?( id )
    (id.is_a? Integer) && ( id > -1 ) && ( id < @muffins.size )
  end

  def add_raw( content, content_type="text/plain" )  # muffinTin not allowed to know what contents are.
    m = Muffin.new( next_id, content, content_type )
    @muffins << m
    m
  end

  def dangerously_all_muffins   #yep, dangerous. remove eventually
    @muffins
  end



end

#===== class Baker ==============
# knows the handlings of muffins.

class Baker

  def initialize
    @muffinTin = MuffinTin.new
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def muffin_at(id) ;  @muffinTin.at( id ) ;  end
  def is_legit?(id) ;  @muffinTin.is_legit?(id) ;  end
  def default_muffin_id ; @muffinTin.default_muffin_id ; end

  def dangerously_all_muffins   #yep, dangerous. remove eventually
    @muffinTin.dangerously_all_muffins
  end

  def dangerously_all_muffins_for_viewing   #yep, dangerous. remove eventually
    views = @muffinTin.dangerously_all_muffins.collect{ |m| m.for_viewing }
  end

  def all_collections_just_ids #not dangerous, but dangerously slow (linear in #muffins )
    collections = @muffinTin.dangerously_all_muffins.select{ |m| m.collection?}
    ids = collections.collect{ |m| m.id }
  end

  def muffin_at_id( m_id )
    muffin_at(m_id) if is_legit?(m_id)
  end


  def add_muffin_from_text( request ) # modify the Request!
    m = @muffinTin.add_raw( request.incoming_contents )
    request.record_muffin_id( m.id )
    m
  end

  def add_muffin_from_file( request ) # modify the Request!
    c, t = multipart_contents_and_type( request )
    return nil unless c && t  #make sure there are contents to add
    m = @muffinTin.add_raw( c, t )
    request.record_muffin_id( m.id )
    m
  end


  def make_collection( request )
    return nil unless is_legit?( id = request.incoming_muffin_id )
    m = muffin_at( id )
    m.make_collection
    m
  end

  def make_noncollection( request )
    return nil unless is_legit?( id = request.incoming_muffin_id )
    m = muffin_at( id )
    m.make_noncollection
    m
  end



  def change_muffin( request )
    return nil if !is_legit?( id = request.incoming_muffin_id )
    m = muffin_at( id )
    m.new_contents( request.incoming_contents )
    m
  end

  def change_muffin_from_file( request )
    c, t = multipart_contents_and_type( request )
    return nil unless c && t  #make sure there are contents to add
    return nil if !is_legit?( id = request.incoming_muffin_id )
    m = muffin_at( id )
    m.new_contents( request.content_of_file_upload, request.content_type_of_file_upload )
    m
  end


  def tag_muffin_per_request( request )
    m_id = request.incoming_muffin_id
    c_id = request.incoming_collector_id
    return nil if !is_legit?( m_id )
    return nil if !is_legit?( c_id )
    m = muffin_at( m_id )
    c = muffin_at( c_id )
    m.add_to_collection( c ) ;
    m
  end


  def multipart_contents_and_type request # binary and ascii file uploads
  # NOTE: bad failure for improper hash structure :(
    (multipart = Rack::Multipart.parse_multipart request.theEnv) ? true : return
    (file_info = multipart.values.find {|f| f.is_a? Hash and f.key? :tempfile }) ? true : return
    (type = file_info[:type])  ? true : return
    (body = file_info[:tempfile].read)  ? true : return
    file_info[:tempfile].close
    file_info[:tempfile].unlink
    [body, type]
  end

end


