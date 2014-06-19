module Production::DowntimeHelper
 
 
 def build_downtime_form(downtime,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:downtime_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: downtime_sub_types
	combos_js_for_downtime_sub_types = gen_combos_clear_js_for_combos(["downtime_downtime_category_code","downtime_downtime_division_code","downtime_downtime_type_code","downtime_downtime_sub_type_code","downtime_external_ref"])
	#Observers for combos representing the key fields of fkey table: downtime_sub_type_id
	downtime_category_code_observer  = {:updated_field_id => "downtime_division_code_cell",
					 :remote_method => 'downtime_downtime_category_code_changed',
					 :on_completed_js => combos_js_for_downtime_sub_types ["downtime_downtime_category_code"]}

	session[:downtime_form][:downtime_category_code_observer] = downtime_category_code_observer

	downtime_division_code_observer  = {:updated_field_id => "downtime_type_code_cell",
					 :remote_method => 'downtime_downtime_division_code_changed',
					 :on_completed_js => combos_js_for_downtime_sub_types ["downtime_downtime_division_code"]}

	session[:downtime_form][:downtime_division_code_observer] = downtime_division_code_observer

	downtime_type_code_observer  = {:updated_field_id => "downtime_sub_type_code_cell",
					 :remote_method => 'downtime_downtime_type_code_changed',
					 :on_completed_js => combos_js_for_downtime_sub_types ["downtime_downtime_type_code"]}

	session[:downtime_form][:downtime_type_code_observer] = downtime_type_code_observer

	downtime_sub_type_code_observer  = {:updated_field_id => "external_ref_cell",
					 :remote_method => 'downtime_downtime_sub_type_code_changed',
					 :on_completed_js => combos_js_for_downtime_sub_types ["downtime_downtime_sub_type_code"]}

	session[:downtime_form][:downtime_sub_type_code_observer] = downtime_sub_type_code_observer

#	combo lists for table: downtime_sub_types

	downtime_category_codes = nil 
	downtime_division_codes = nil 
	downtime_type_codes = nil 
	downtime_sub_type_codes = nil 
	external_refs = nil 
 
	downtime_category_codes = Downtime.get_all_downtime_category_codes
	if downtime == nil||is_create_retry
		 downtime_division_codes = ["Select a value from downtime_category_code"]
		 downtime_type_codes = ["Select a value from downtime_division_code"]
		 downtime_sub_type_codes = ["Select a value from downtime_type_code"]
		 external_refs = ["Select a value from downtime_sub_type_code"]
	else
		downtime_division_codes = Downtime.downtime_division_codes_for_downtime_category_code(downtime.downtime_sub_type.downtime_category_code)
		downtime_type_codes = Downtime.downtime_type_codes_for_downtime_division_code_and_downtime_category_code(downtime.downtime_sub_type.downtime_division_code, downtime.downtime_sub_type.downtime_category_code)
		downtime_sub_type_codes = Downtime.downtime_sub_type_codes_for_downtime_type_code_and_downtime_division_code_and_downtime_category_code(downtime.downtime_sub_type.downtime_type_code, downtime.downtime_sub_type.downtime_division_code, downtime.downtime_sub_type.downtime_category_code)
		external_refs = Downtime.external_refs_for_downtime_sub_type_code_and_downtime_type_code_and_downtime_division_code_and_downtime_category_code(downtime.downtime_sub_type.downtime_sub_type_code, downtime.downtime_sub_type.downtime_type_code, downtime.downtime_sub_type.downtime_division_code, downtime.downtime_sub_type.downtime_category_code)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'DateField',
						:field_name => 'from_date'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'from_time'}

	field_configs[2] = {:field_type => 'DateField',
						:field_name => 'to_date'}

	field_configs[3] = {:field_type => 'TextField',
						:field_name => 'to_time'}

	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'downtime_minute',
						:settings => {:label_caption => 'production downtime minute'}} 

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (downtime_sub_type_id) on related table: downtime_sub_types
#	----------------------------------------------------------------------------------------------
	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'downtime_category_code',
						:settings => {:list => downtime_category_codes},
						:observer => downtime_category_code_observer}
 
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'downtime_division_code',
						:settings => {:list => downtime_division_codes},
						:observer => downtime_division_code_observer}
 
	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'downtime_type_code',
						:settings => {:list => downtime_type_codes},
						:observer => downtime_type_code_observer}
 
	field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'downtime_sub_type_code',
						:settings => {:list => downtime_sub_type_codes},
						:observer => downtime_sub_type_code_observer}
 
	field_configs[9] =  {:field_type => 'DropDownField',
						:field_name => 'external_ref',
						:settings => {:list => external_refs}}
 
	field_configs[10] = {:field_type => 'TextField',
						:field_name => 'reason'}

	field_configs[11] = {:field_type => 'TextField',
						:field_name => 'line'}

	build_form(downtime,field_configs,action,'downtime',caption,is_edit)

end
 
 
 def build_downtime_search_form(downtime,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:downtime_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["downtime_downtime_category_code","downtime_downtime_division_code","downtime_downtime_type_code","downtime_downtime_sub_type_code","downtime_external_ref"])
	#Observers for search combos
	downtime_category_code_observer  = {:updated_field_id => "downtime_division_code_cell",
					 :remote_method => 'downtime_downtime_category_code_search_combo_changed',
					 :on_completed_js => search_combos_js["downtime_downtime_category_code"]}

	session[:downtime_search_form][:downtime_category_code_observer] = downtime_category_code_observer

	downtime_division_code_observer  = {:updated_field_id => "downtime_type_code_cell",
					 :remote_method => 'downtime_downtime_division_code_search_combo_changed',
					 :on_completed_js => search_combos_js["downtime_downtime_division_code"]}

	session[:downtime_search_form][:downtime_division_code_observer] = downtime_division_code_observer

	downtime_type_code_observer  = {:updated_field_id => "downtime_sub_type_code_cell",
					 :remote_method => 'downtime_downtime_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["downtime_downtime_type_code"]}

	session[:downtime_search_form][:downtime_type_code_observer] = downtime_type_code_observer

	downtime_sub_type_code_observer  = {:updated_field_id => "external_ref_cell",
					 :remote_method => 'downtime_downtime_sub_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["downtime_downtime_sub_type_code"]}

	session[:downtime_search_form][:downtime_sub_type_code_observer] = downtime_sub_type_code_observer

 
	downtime_category_codes = Downtime.find_by_sql('select distinct downtime_category_code from downtimes').map{|g|[g.downtime_category_code]}
	downtime_category_codes.unshift("<empty>")
	if is_flat_search
		downtime_division_codes = Downtime.find_by_sql('select distinct downtime_division_code from downtimes').map{|g|[g.downtime_division_code]}
		downtime_division_codes.unshift("<empty>")
		downtime_type_codes = Downtime.find_by_sql('select distinct downtime_type_code from downtimes').map{|g|[g.downtime_type_code]}
		downtime_type_codes.unshift("<empty>")
		downtime_sub_type_codes = Downtime.find_by_sql('select distinct downtime_sub_type_code from downtimes').map{|g|[g.downtime_sub_type_code]}
		downtime_sub_type_codes.unshift("<empty>")
		external_refs = Downtime.find_by_sql('select distinct external_ref from downtimes').map{|g|[g.external_ref]}
		external_refs.unshift("<empty>")
		downtime_category_code_observer = nil
		downtime_division_code_observer = nil
		downtime_type_code_observer = nil
		downtime_sub_type_code_observer = nil
	else
		 downtime_division_codes = ["Select a value from downtime_category_code"]
		 downtime_type_codes = ["Select a value from downtime_division_code"]
		 downtime_sub_type_codes = ["Select a value from downtime_type_code"]
		 external_refs = ["Select a value from downtime_sub_type_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'downtime_category_code',
						:settings => {:list => downtime_category_codes},
						:observer => downtime_category_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'downtime_division_code',
						:settings => {:list => downtime_division_codes},
						:observer => downtime_division_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'downtime_type_code',
						:settings => {:list => downtime_type_codes},
						:observer => downtime_type_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'downtime_sub_type_code',
						:settings => {:list => downtime_sub_type_codes},
						:observer => downtime_sub_type_code_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'external_ref',
						:settings => {:list => external_refs}}
 
	build_form(downtime,field_configs,action,'downtime',caption,false)

end



 def build_downtime_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'from_date'}
	column_configs[1] = {:field_type => 'text',:field_name => 'from_time'}
	column_configs[2] = {:field_type => 'text',:field_name => 'to_date'}
	column_configs[3] = {:field_type => 'text',:field_name => 'to_time'}
	column_configs[4] = {:field_type => 'text',:field_name => 'downtime_minute'}
	column_configs[5] = {:field_type => 'text',:field_name => 'downtime_category_code'}
	column_configs[6] = {:field_type => 'text',:field_name => 'downtime_division_code'}
	column_configs[7] = {:field_type => 'text',:field_name => 'downtime_type_code'}
	column_configs[8] = {:field_type => 'text',:field_name => 'downtime_sub_type_code'}
	column_configs[9] = {:field_type => 'text',:field_name => 'reason'}
	column_configs[10] = {:field_type => 'text',:field_name => 'line'}
	column_configs[11] = {:field_type => 'text',:field_name => 'external_ref'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit downtime',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_downtime',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete downtime',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_downtime',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
