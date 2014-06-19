module Fg::LoadVehicleHelper


  def build_load_vehicle_form(load_vehicle, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:load_vehicle_form]= Hash.new
    load_numbers = Load.find_by_sql('select distinct load_number from loads').map { |g| [g.load_number] }
    load_numbers.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (load_id) on related table: loads
#	-----------------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'load_number',
                         :settings => {:list => load_numbers}}


    field_configs[1] = {:field_type => 'TextField',
                        :field_name => 'vehicle_number'}

    field_configs[2] = {:field_type => 'TextField',
                        :field_name => 'vehicle_weight_out'}

    build_form(load_vehicle, field_configs, action, 'load_vehicle', caption, is_edit)

  end


  def build_load_vehicle_search_form(load_vehicle, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:load_vehicle_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    vehicle_numbers = LoadVehicle.find_by_sql('select distinct vehicle_number from load_vehicles').map { |g| [g.vehicle_number] }
    vehicle_numbers.unshift("<empty>")
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'vehicle_number',
                         :settings => {:list => vehicle_numbers}}

    build_form(load_vehicle, field_configs, action, 'load_vehicle', caption, false)

  end


  def build_load_vehicle_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text', :field_name => 'vehicle_number'}
    column_configs[1] = {:field_type => 'text', :field_name => 'vehicle_weight_out'}
#	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit load_vehicle',
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_load_vehicle',
                                                          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete load_vehicle',
                                                 :settings =>
                                                         {:link_text => 'delete',
                                                          :target_action => 'delete_load_vehicle',
                                                          :id_column => 'id'}}
    end
    return get_data_grid(data_set, column_configs)
  end

end
