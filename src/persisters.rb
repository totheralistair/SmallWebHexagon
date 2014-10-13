require_relative '../src/ml_request'
require_relative '../test/utilities_for_tests'

class Nul_persister
  def handle_new_post p
    # p p.yamld
  end
end


class File_persister
  def initialize fn
    @myFn = fn
    prepare_for_file fn
  end

  def handle_new_post p
    File.open( @myFn, 'a') do |f| f << p.yamld end
  end
end
