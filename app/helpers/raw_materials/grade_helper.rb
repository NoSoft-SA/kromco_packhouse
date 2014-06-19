module RawMaterials::GradeHelper
 
 
 def build_grade_form(grade,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:grade_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'grade_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'grade_description'}
						
	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'qa_level'}

    field_configs[3] = {:field_type => 'CheckBox',
    						:field_name => 'has_recooling_fees'}

    field_configs[4] = {:field_type => 'CheckBox',
     						:field_name => 'has_carton_manufacturing_fees'}

    field_configs[5] = {:field_type => 'CheckBox',
        						:field_name => 'has_handling_dispatch_fees'}

	build_form(grade,field_configs,action,'grade',caption,is_edit)

end
 
 
 def build_grade_search_form(grade,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:grade_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["grade_grade_code"])
	#Observers for search combos
 
	grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map{|g|[g.grade_code]}
	grade_codes.unshift("<empty>")
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
						:field_name => 'grade_code',
						:settings => {:list => grade_codes}}
 
	build_form(grade,field_configs,action,'grade',caption,false)

end



 def build_grade_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'grade_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'grade_description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'qa_level'}
  column_configs[3] = {:field_type => 'text',:field_name => 'has_recooling_fees'}
  column_configs[4] = {:field_type => 'text',:field_name => 'has_carton_manufacturing_fees'}
    column_configs[5] = {:field_type => 'text',:field_name => 'has_handling_dispatch_fees'}

#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit grade',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_grade',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete grade',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_grade',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
