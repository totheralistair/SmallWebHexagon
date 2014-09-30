# The API outputs of Muffinland, put in a separate file for easier maintenance
class Muffinland

  def ml_response_for_EmptyDB
    ml_response = {
        out_action:   "EmptyDB"
    }
  end

  def ml_response_for_GET_muffin( muffin )
    ml_response = { 
        out_action:   "GET_named_page",
        muffin_id:   muffin.id,
        muffin_content_type:   muffin.content_type,
        muffin_body:   muffin.for_viewing,
        muffin_is_collection:   muffin.collection?,
        muffin_collects:   muffin.collects_ids,
        belongs_to_ids:   muffin.belongs_to_ids,
        all_collections_just_ids:
            @theBaker.all_collections_just_ids,
        dangerously_all_muffins_for_viewing:
            @theBaker.dangerously_all_muffins_for_viewing,
        #        :dangerously_all_posts  
        #            @theHistorian.dangerously_all_posts#.map{|req|req.inspect}
    }
  end

  def ml_response_for_UnregisteredCommand
    ml_response = {
        out_action:   "Unregistered Command"
    }
  end

  def ml_response_for_404_basic( request )
    ml_response = {
        out_action:  "404",
        error_message: "Nothing at this location",
        requested_name:   request.name_from_path,
        dangerously_all_muffins_for_viewing:
            @theBaker.dangerously_all_muffins_for_viewing,
        # :dangerously_all_posts  
        #     @theHistorian.dangerously_all_posts#.map{|req|req.inspect}
    }
  end

  def ml_response_for_400_no_file_provided( request )
    ml_response = {
        out_action:   "400_no_file_selected",
        error_message: "No file selected",
        requested_name:   request.name_from_path,
        dangerously_all_muffins_for_viewing:
            @theBaker.dangerously_all_muffins_for_viewing,
        # :dangerously_all_posts  
        #     @theHistorian.dangerously_all_posts#.map{|req|req.inspect}
    }
  end

end

