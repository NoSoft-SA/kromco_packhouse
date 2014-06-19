module Fg::LoadVoyageHelper


  def build_load_voyage_form(load_voyage, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:load_voyage_form]= Hash.new

    exporter_party_role_ids = PartiesRole.find_by_sql("SELECT * FROM public.parties_roles WHERE parties_roles.role_name = 'EXPORTER'").map { |g| [g.party_name, g.id] }
    shipper_party_role_ids = PartiesRole.find_by_sql("SELECT * FROM public.parties_roles WHERE parties_roles.role_name = 'SHIPPER'").map { |g| [g.party_name, g.id] }
    shipping_agent_party_role_ids = PartiesRole.find_by_sql("SELECT * FROM public.parties_roles WHERE parties_roles.role_name = 'SHIPPING AGENT'").map { |g| [g.party_name, g.id] }
    shipping_line_party_role_ids = PartiesRole.find_by_sql("SELECT * FROM public.parties_roles WHERE parties_roles.role_name = 'SHIPPING LINE'").map { |g| [g.party_name, g.id] }

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (load_id) on related table: loads
#	-----------------------------------------------------------------------------------------------------

#    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'voyage_id'}
#    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'load_id'}


    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'customer_reference'}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'booking_reference'}

    field_configs[field_configs.length()] =  {:field_type => 'TextField', :field_name => 'exporter_certificate_code'}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'exporter_party_role_id',
                                              :settings => {:list => exporter_party_role_ids}}
    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'shipper_party_role_id',
                                              :settings => {:list => shipper_party_role_ids}}
    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'shipping_agent_party_role_id',
                                              :settings => {:list => shipping_agent_party_role_ids}}
    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'shipping_line_party_id',
                                              :settings => {:list => shipping_line_party_role_ids}}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'memo_pad'}


    build_form(load_voyage, field_configs, action, 'load_voyage', caption, is_edit)

  end


  def build_load_voyage_search_form(load_voyage, action, caption, is_flat_search = nil)
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

    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'vehicle_number',
                         :settings => {:list => vehicle_numbers}}

    build_form(load_voyage, field_configs, action, 'load_voyage', caption, false)

  end


  def build_load_voyage_grid(data_set, can_edit, can_delete)

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
