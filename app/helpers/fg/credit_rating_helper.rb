module Fg::CreditRatingHelper


  def build_credit_rating_form(credit_rating, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:credit_rating_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
    field_configs[0] = {:field_type => 'TextField',
                        :field_name => 'credit_code'}

    field_configs[1] = {:field_type => 'TextField',
                        :field_name => 'credit_desriptio'}

    build_form(credit_rating, field_configs, action, 'credit_rating', caption, is_edit)

  end


  def build_credit_rating_search_form(credit_rating, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:credit_rating_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    credit_codes = CreditRating.find_by_sql('select distinct credit_code from credit_ratings').map { |g| [g.credit_code] }
    credit_codes.unshift("<empty>")
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'credit_code',
                         :settings => {:list => credit_codes}}

    build_form(credit_rating, field_configs, action, 'credit_rating', caption, false)

  end


  def build_credit_rating_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text', :field_name => 'credit_code'}
    column_configs[1] = {:field_type => 'text', :field_name => 'credit_description'}
#	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit credit_rating',
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_credit_rating',
                                                          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete credit_rating',
                                                 :settings =>
                                                         {:link_text => 'delete',
                                                          :target_action => 'delete_credit_rating',
                                                          :id_column => 'id'}}
    end
    return get_data_grid(data_set, column_configs)
  end

end
