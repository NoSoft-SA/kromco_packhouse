module QualityControl::InspectionTypeHelper
 
 
 def build_inspection_type_form(inspection_type,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:inspection_type_form]= Hash.new
	grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map{|g|[g.grade_code]}
	grade_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'inspection_type_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'inspection_type_description'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (grade_id) on related table: grades
#	----------------------------------------------------------------------------------------------
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grade_codes}}

    field_configs[3] = {:field_type => 'CheckBox',
                        :field_name => 'for_internal_hg_inspections_only'}
 
	build_form(inspection_type,field_configs,action,'inspection_type',caption,is_edit)

end
 
 
 def build_inspection_type_search_form(inspection_type,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:inspection_type_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["inspection_type_inspection_type_code","inspection_type_grade_code"])
	#Observers for search combos
	inspection_type_code_observer  = {:updated_field_id => "grade_code_cell",
					 :remote_method => 'inspection_type_inspection_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["inspection_type_inspection_type_code"]}

	session[:inspection_type_search_form][:inspection_type_code_observer] = inspection_type_code_observer

 
	inspection_type_codes = InspectionType.find_by_sql('select distinct inspection_type_code from inspection_types').map{|g|[g.inspection_type_code]}
	inspection_type_codes.unshift("<empty>")
	if is_flat_search
		grade_codes = InspectionType.find_by_sql('select distinct grade_code from inspection_types').map{|g|[g.grade_code]}
		grade_codes.unshift("<empty>")
		inspection_type_code_observer = nil
	else
		 grade_codes = ["Select a value from inspection_type_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'inspection_type_code',
						:settings => {:list => inspection_type_codes},
						:observer => inspection_type_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grade_codes}}
 
	build_form(inspection_type,field_configs,action,'inspection_type',caption,false)

end



 def build_inspection_type_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'inspection_type_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'inspection_type_description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'grade_code'}
  column_configs[3] = {:field_type => 'text',:field_name => 'for_internal_hg_inspections_only'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit inspection_type',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_inspection_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete inspection_type',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_inspection_type',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
