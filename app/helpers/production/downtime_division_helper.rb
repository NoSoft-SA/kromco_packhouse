module Production::DowntimeDivisionHelper
 
 
 def build_downtime_division_form(downtime_division,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:downtime_division_form]= Hash.new
	downtime_category_codes = DowntimeCategory.find_by_sql('select distinct downtime_category_code from downtime_categories').map{|g|[g.downtime_category_code]}
	downtime_category_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'downtime_division_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (downtime_category_id) on related table: downtime_categories
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'downtime_category_code',
						:settings => {:list => downtime_category_codes}}
 
	build_form(downtime_division,field_configs,action,'downtime_division',caption,is_edit)

end
 
 
 def build_downtime_division_search_form(downtime_division,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:downtime_division_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["downtime_division_downtime_category_code","downtime_division_downtime_division_code"])
	#Observers for search combos
	downtime_category_code_observer  = {:updated_field_id => "downtime_division_code_cell",
					 :remote_method => 'downtime_division_downtime_category_code_search_combo_changed',
					 :on_completed_js => search_combos_js["downtime_division_downtime_category_code"]}

	session[:downtime_division_search_form][:downtime_category_code_observer] = downtime_category_code_observer

 
	downtime_category_codes = DowntimeDivision.find_by_sql('select distinct downtime_category_code from downtime_divisions').map{|g|[g.downtime_category_code]}
	downtime_category_codes.unshift("<empty>")
	if is_flat_search
		downtime_division_codes = DowntimeDivision.find_by_sql('select distinct downtime_division_code from downtime_divisions').map{|g|[g.downtime_division_code]}
		downtime_division_codes.unshift("<empty>")
		downtime_category_code_observer = nil
	else
		 downtime_division_codes = ["Select a value from downtime_category_code"]
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
						:settings => {:list => downtime_division_codes}}
 
	build_form(downtime_division,field_configs,action,'downtime_division',caption,false)

end



 def build_downtime_division_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'downtime_division_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'downtime_category_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit downtime_division',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_downtime_division',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete downtime_division',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_downtime_division',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
