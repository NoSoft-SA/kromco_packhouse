module Fg::VesselHelper


  def build_vessel_form(vessel, action, caption, is_edit = nil, is_create_retry = nil)


  ship_owners_role_ids = PartiesRole.find_by_sql("SELECT id, parties_roles.party_name FROM public.parties_roles WHERE parties_roles.role_name = 'SHIP OWNER'").map{|g|[g.party_name, g.id]}
  #ship_owners_role_ids.unshift(["<empty>","<empty>"])


#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:vessel_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
    field_configs[0] = {:field_type => 'TextField',
                        :field_name => 'vessel_code'}

    field_configs[1] = {:field_type => 'TextField',
                        :field_name => 'vessel_registration_number'}

    field_configs[2] = {:field_type => 'TextField',
                        :field_name => 'vessel_description'}

    field_configs[3] =  {:field_type => 'DropDownField',
                       :field_name => 'owner_party_role_id',
                       :settings => { :label_caption => 'vessel owner',:show_label=> true,
                               :list => ship_owners_role_ids}}

    build_form(vessel, field_configs, action, 'vessel', caption, is_edit)

  end


  def build_vessel_search_form(vessel, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:vessel_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    vessel_codes = Vessel.find_by_sql('select distinct vessel_code from vessels').map { |g| [g.vessel_code] }
    vessel_codes.unshift("<empty>")
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'vessel_code',
                         :settings => {:list => vessel_codes}}

    build_form(vessel, field_configs, action, 'vessel', caption, false)

  end


  def build_vessel_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text', :field_name => 'vessel_code',:col_width=>211}
    column_configs[1] = {:field_type => 'text', :field_name => 'vessel_registration_number',:col_width=>146}
    column_configs[2] = {:field_type => 'text', :field_name => 'vessel_description',:col_width=>181}
    column_configs[3] = {:field_type => 'text', :field_name => 'vessel_owner',:col_width=>316}

#	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit',:col_width=>45,
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_vessel',
                                                          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete',:col_width=>60,
                                                 :settings =>
                                                         {:link_text => 'delete',
                                                          :target_action => 'delete_vessel',
                                                          :id_column => 'id'}}
    end
    return get_data_grid(data_set, column_configs)
  end

end
