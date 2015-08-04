module RawMaterials::RmtVarietyQcLevelHelper
 
 
 def build_rmt_variety_qc_level_form(rmt_variety_qc_level,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:rmt_variety_qc_level_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: seasons
	combos_js_for_seasons = gen_combos_clear_js_for_combos(["rmt_variety_qc_level_season_code","rmt_variety_qc_level_id"])
	combos_js_for_rmt_varieties = gen_combos_clear_js_for_combos(["rmt_variety_qc_level_commodity_code","rmt_variety_qc_level_rmt_variety_code"])
	#Observers for combos representing the key fields of fkey table: season_id
	#generate javascript for the on_complete ajax event for each combo for fk table: rmt_varieties
	combos_js_for_seasons = gen_combos_clear_js_for_combos(["rmt_variety_qc_level_season_code","rmt_variety_qc_level_id"])
	combos_js_for_rmt_varieties = gen_combos_clear_js_for_combos(["rmt_variety_qc_level_commodity_code","rmt_variety_qc_level_rmt_variety_code"])
	#Observers for combos representing the key fields of fkey table: rmt_variety_id
	season_code_observer  = {:updated_field_id => "id_cell",
					 :remote_method => 'rmt_variety_qc_level_season_code_changed',
					 :on_completed_js => combos_js_for_seasons ["rmt_variety_qc_level_season_code"]}

	session[:rmt_variety_qc_level_form][:season_code_observer] = season_code_observer

#	combo lists for table: seasons

	season_codes = nil 
	ids = nil 
 
	season_codes = RmtVarietyQcLevel.get_all_season_codes
	if rmt_variety_qc_level == nil||is_create_retry
		 ids = ["Select a value from season_code"]
	else
		ids = RmtVarietyQcLevel.ids_for_season_code(rmt_variety_qc_level.season.season_code)
	end
	commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
					 :remote_method => 'rmt_variety_qc_level_commodity_code_changed',
					 :on_completed_js => combos_js_for_rmt_varieties ["rmt_variety_qc_level_commodity_code"]}

	session[:rmt_variety_qc_level_form][:commodity_code_observer] = commodity_code_observer

#	combo lists for table: rmt_varieties

	commodity_codes = nil 
	rmt_variety_codes = nil 
 
	commodity_codes = RmtVarietyQcLevel.get_all_commodity_codes
	if rmt_variety_qc_level == nil||is_create_retry
		 rmt_variety_codes = ["Select a value from commodity_code"]
	else
		rmt_variety_codes = RmtVarietyQcLevel.rmt_variety_codes_for_commodity_code(rmt_variety_qc_level.rmt_variety.commodity_code)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = []
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (season_id) on related table: seasons
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'season_code',
						:settings => {:list => season_codes},
						:observer => season_code_observer}
 
#	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
#						:field_name => 'id',
#						:settings => {:list => ids}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (rmt_variety_id) on related table: rmt_varieties
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_code',
						:settings => {:list => rmt_variety_codes}}
 
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'max_pressure'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'min_pressure'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'min_sugar'}

#	field_configs[field_configs.length()] = {:field_type => 'TextField',
#						:field_name => 'affected_by_env'}

#	field_configs[field_configs.length()] = {:field_type => 'TextField',
#						:field_name => 'affected_by_function'}

#	field_configs[field_configs.length()] = {:field_type => 'TextField',
#						:field_name => 'affected_by_program'}

#	field_configs[field_configs.length()] = {:field_type => 'DateTimeField',
#						:field_name => 'created_at'}

#	field_configs[field_configs.length()] = {:field_type => 'TextField',
#						:field_name => 'created_by'}

#	field_configs[field_configs.length()] = {:field_type => 'DateTimeField',
#						:field_name => 'updated_at'}

#	field_configs[field_configs.length()] = {:field_type => 'TextField',
#						:field_name => 'updated_by'}

	build_form(rmt_variety_qc_level,field_configs,action,'rmt_variety_qc_level',caption,is_edit)

end
 
 
 def build_rmt_variety_qc_level_search_form(rmt_variety_qc_level,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:rmt_variety_qc_level_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["rmt_variety_qc_level_id","rmt_variety_qc_level_season_id","rmt_variety_qc_level_rmt_variety_id"])
	#Observers for search combos
	id_observer  = {:updated_field_id => "season_id_cell",
					 :remote_method => 'rmt_variety_qc_level_id_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_variety_qc_level_id"]}

	session[:rmt_variety_qc_level_search_form][:id_observer] = id_observer

	season_id_observer  = {:updated_field_id => "rmt_variety_id_cell",
					 :remote_method => 'rmt_variety_qc_level_season_id_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_variety_qc_level_season_id"]}

	session[:rmt_variety_qc_level_search_form][:season_id_observer] = season_id_observer

 
	ids = RmtVarietyQcLevel.find_by_sql('select distinct id from rmt_variety_qc_levels').map{|g|[g.id]}
	ids.unshift("<empty>")
	if is_flat_search
		season_ids = RmtVarietyQcLevel.find_by_sql('select distinct season_id from rmt_variety_qc_levels').map{|g|[g.season_id]}
		season_ids.unshift("<empty>")
		rmt_variety_ids = RmtVarietyQcLevel.find_by_sql('select distinct rmt_variety_id from rmt_variety_qc_levels').map{|g|[g.rmt_variety_id]}
		rmt_variety_ids.unshift("<empty>")
		id_observer = nil
		season_id_observer = nil
	else
		 season_ids = ["Select a value from id"]
		 rmt_variety_ids = ["Select a value from season_id"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = []
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'id',
						:settings => {:list => ids},
						:observer => id_observer}
 
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'season_id',
						:settings => {:list => season_ids},
						:observer => season_id_observer}
 
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_id',
						:settings => {:list => rmt_variety_ids}}
 
	build_form(rmt_variety_qc_level,field_configs,action,'rmt_variety_qc_level',caption,false)

end



 def build_rmt_variety_qc_level_grid(data_set,can_edit,can_delete)

	column_configs = []
	column_configs << {:field_type => 'text',:field_name => 'max_pressure'}
	column_configs << {:field_type => 'text',:field_name => 'min_pressure'}
	column_configs << {:field_type => 'text',:field_name => 'min_sugar'}
	column_configs << {:field_type => 'text',:field_name => 'affected_by_env'}
	column_configs << {:field_type => 'text',:field_name => 'affected_by_function'}
	column_configs << {:field_type => 'text',:field_name => 'affected_by_program'}
	column_configs << {:field_type => 'text',:field_name => 'created_at'}
	column_configs << {:field_type => 'text',:field_name => 'created_by'}
	column_configs << {:field_type => 'text',:field_name => 'updated_at'}
	column_configs << {:field_type => 'text',:field_name => 'updated_by'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs << {:field_type => 'action',:field_name => 'edit rmt_variety_qc_level',
			:column_caption => 'Edit',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_rmt_variety_qc_level',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete rmt_variety_qc_level',
			:column_caption => 'Delete',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_rmt_variety_qc_level',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end



  def build_rmt_variety_qc_level_dm_grid(data_set, stat, columns_list, can_edit, can_delete, grid_configs)

    column_configs = []

    # ----------------------
    # define action columns
    # ----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit rmt_variety_qc_level',
        :column_caption => 'Edit',
        :settings =>
      {:link_text => 'edit',
        :target_action => 'edit_rmt_variety_qc_level',
        :id_column => 'id'}}
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete rmt_variety_qc_level',
        :column_caption => 'Delete',
        :settings =>
      {:link_text => 'delete',
        :target_action => 'delete_rmt_variety_qc_level',
        :id_column => 'id'}}
    end

    # Build all other columns from the dataminer yml file.
    build_generic_column_configs(data_set, column_configs, stat, columns_list, grid_configs)

    # Get any other datagrid options from the grid_configs...
    opts = build_grid_options_from_grid_configs(grid_configs)

    get_data_grid(data_set, column_configs, nil, true, nil, opts)
  end

end
