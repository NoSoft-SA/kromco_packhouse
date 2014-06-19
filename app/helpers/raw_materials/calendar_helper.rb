module RawMaterials::CalendarHelper
 
 def build_iso_week_form(iso_week,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:iso_week_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'iso_week_code'}

	field_configs[1] = {:field_type => 'DateField',
						:field_name => 'iso_date_from'}

	field_configs[2] = {:field_type => 'DateField',
						:field_name => 'iso_date_to'}

	build_form(iso_week,field_configs,action,'iso_week',caption,is_edit)

end
 
 
 def build_iso_week_search_form(iso_week,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:iso_week_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["iso_week_iso_date_from"])
	#Observers for search combos
 
	iso_date_froms = IsoWeek.find_by_sql('select distinct iso_date_from from iso_weeks').map{|g|[g.iso_date_from]}
	iso_date_froms.unshift("<empty>")
	if is_flat_search
	else
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'iso_date_from',
						:settings => {:list => iso_date_froms}}
 
	build_form(iso_week,field_configs,action,'iso_week',caption,false)

end



 def build_iso_week_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'iso_week_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'iso_date_from'}
	column_configs[2] = {:field_type => 'text',:field_name => 'iso_date_to'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit iso_week',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_iso_week',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete iso_week',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_iso_week',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 #============
 #SEASON CODE
 #============
 def build_season_form(season,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:season_form]= Hash.new
	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'season_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'season_description'}

	field_configs[2] = {:field_type => 'DateField',
						:field_name => 'start_date'}

	field_configs[3] = {:field_type => 'DateField',
						:field_name => 'end_date'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (commodity_id) on related table: commodities
#	----------------------------------------------------------------------------------------------
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes}}
 
	field_configs[5] = {:field_type => 'TextField',
						:field_name => 'season'}

	build_form(season,field_configs,action,'season',caption,is_edit)

end
 
 
 def build_season_search_form(season,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:season_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["season_season_code","season_commodity_code"])
	#Observers for search combos
	season_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'season_season_code_search_combo_changed',
					 :on_completed_js => search_combos_js["season_season_code"]}

	session[:season_search_form][:season_code_observer] = season_code_observer

 
	season_codes = Season.find_by_sql('select distinct season_code from seasons').map{|g|[g.season_code]}
	season_codes.unshift("<empty>")
	if is_flat_search
		commodity_codes = Season.find_by_sql('select distinct commodity_code from seasons').map{|g|[g.commodity_code]}
		commodity_codes.unshift("<empty>")
		season_code_observer = nil
	else
		 commodity_codes = ["Select a value from season_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'season_code',
						:settings => {:list => season_codes},
						:observer => season_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes}}
 
	build_form(season,field_configs,action,'season',caption,false)

end



 def build_season_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'season_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'season_description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'start_date'}
	column_configs[3] = {:field_type => 'text',:field_name => 'end_date'}
	column_configs[4] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'season'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit season',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_season',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete season',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_season',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
