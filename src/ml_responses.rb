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
        muffin_body:   muffin.for_viewing
    }
  end


  def ml_response_for_404_basic( request )
    ml_response = {
        out_action:  "404",
        error_message: "Nothing at this location",
        requested_name:   request.name_from_path
    }
  end

end

