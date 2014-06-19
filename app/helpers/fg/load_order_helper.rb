module Fg::LoadOrderHelper


  def build_load_order_form(load_order, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:load_order_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo for fk table: orders
    combos_js_for_orders = gen_combos_clear_js_for_combos(["load_order_order_number", "load_order_customer_party_role_id"])
    combos_js_for_vehicle_jobs = gen_combos_clear_js_for_combos(["load_order_id", "load_order_vehicle_job_number"])
    #Observers for combos representing the key fields of fkey table: order_id
    #generate javascript for the on_complete ajax event for each combo for fk table: vehicle_jobs
    combos_js_for_orders = gen_combos_clear_js_for_combos(["load_order_order_number", "load_order_customer_party_role_id"])
    combos_js_for_vehicle_jobs = gen_combos_clear_js_for_combos(["load_order_id", "load_order_vehicle_job_number"])
    #Observers for combos representing the key fields of fkey table: vehicle_job_id
    load_numbers = Load.find_by_sql('select distinct load_number from loads').map { |g| [g.load_number] }
    load_numbers.unshift("<empty>")
    order_number_observer  = {:updated_field_id => "customer_party_role_id_cell",
                              :remote_method => 'load_order_order_number_changed',
                              :on_completed_js => combos_js_for_orders ["load_order_order_number"]}

    session[:load_order_form][:order_number_observer] = order_number_observer

#	combo lists for table: orders

    order_numbers = nil
    customer_party_role_ids = nil

    order_numbers = LoadOrder.get_all_order_numbers
    if load_order == nil||is_create_retry
      customer_party_role_ids = ["Select a value from order_number"]
    else
      customer_party_role_ids = LoadOrder.customer_party_role_ids_for_order_number(load_order.order.order_number)
    end
    id_observer  = {:updated_field_id => "vehicle_job_number_cell",
                    :remote_method => 'load_order_id_changed',
                    :on_completed_js => combos_js_for_vehicle_jobs ["load_order_id"]}

    session[:load_order_form][:id_observer] = id_observer

#	combo lists for table: vehicle_jobs

    ids = nil
    vehicle_job_numbers = nil

    ids = LoadOrder.get_all_ids
    if load_order == nil||is_create_retry
      vehicle_job_numbers = ["Select a value from id"]
    else
      vehicle_job_numbers = LoadOrder.vehicle_job_numbers_for_id(load_order.vehicle_job.id)
    end
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


#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (order_id) on related table: orders
#	----------------------------------------------------------------------------------------------
    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'order_number',
                         :settings => {:list => order_numbers},
                         :observer => order_number_observer}

    field_configs[2] =  {:field_type => 'DropDownField',
                         :field_name => 'customer_party_role_id',
                         :settings => {:list => customer_party_role_ids}}

    field_configs[3] = {:field_type => 'DateTimeField',
                        :field_name => 'date_time'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (vehicle_job_id) on related table: vehicle_jobs
#	----------------------------------------------------------------------------------------------
    field_configs[4] =  {:field_type => 'DropDownField',
                         :field_name => 'id',
                         :settings => {:list => ids},
                         :observer => id_observer}

    field_configs[5] =  {:field_type => 'DropDownField',
                         :field_name => 'vehicle_job_number',
                         :settings => {:list => vehicle_job_numbers}}

    build_form(load_order, field_configs, action, 'load_order', caption, is_edit)

  end


  def build_load_order_search_form(load_order, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:load_order_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    date_times = LoadOrder.find_by_sql('select distinct date_time from load_orders').map { |g| [g.date_time] }
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'date_time',
                         :settings => {:list => date_times}}

    build_form(load_order, field_configs, action, 'load_order', caption, false)

  end


  def build_load_order_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text', :field_name => 'date_time'}
    column_configs[1] = {:field_type => 'text', :field_name => 'operator'}
    column_configs[2] = {:field_type => 'text', :field_name => 'order_id'}
    column_configs[3] = {:field_type => 'text', :field_name => 'load_id'}
    column_configs[4] = {:field_type => 'text', :field_name => 'vehicle_job_id'}
#	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit load_order',
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_load_order',
                                                          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete load_order',
                                                 :settings =>
                                                         {:link_text => 'delete',
                                                          :target_action => 'delete_load_order',
                                                          :id_column => 'id'}}
    end
    return get_data_grid(data_set, column_configs)
  end

end
