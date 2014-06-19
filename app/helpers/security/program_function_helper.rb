module Security::ProgramFunctionHelper


 def build_program_function_form(program_function,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:program_function_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: programs
	combos_js_for_programs = gen_combos_clear_js_for_combos(["program_function_program_name","program_function_functional_area_name"])
	#Observers for combos representing the key fields of fkey table: program_id
	program_name_observer  = {:updated_field_id => "functional_area_name_cell",
					 :remote_method => 'program_function_program_name_changed',
					 :on_completed_js => combos_js_for_programs ["program_function_program_name"]}

	session[:program_function_form][:program_name_observer] = program_name_observer

#	combo lists for table: programs

	program_names = nil 
	functional_area_names = nil 
 
	program_names = ProgramFunction.get_all_program_names
	if program_function == nil||is_create_retry
		 functional_area_names = ["Select a value from program_name"]
	else
		functional_area_names = ProgramFunction.functional_area_names_for_program_name(program_function.program.program_name)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (program_id) on related table: programs
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'program_name',
						:settings => {:list => program_names},
						:observer => program_name_observer}
 
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name',
						:settings => {:list => functional_area_names}}
 
	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'name'}

    field_configs << {:field_type => 'TextField',
						:field_name => 'func_area_url_component'}

    field_configs << {:field_type => 'TextField',
						:field_name => 'prog_url_component'}
    
    field_configs << {:field_type => 'TextField',
						:field_name => 'url_param'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'description'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
    						:field_name => 'position'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'display_name'}

  field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'class_name'}
						
#=============
#Luks' Code ==
#=============
#if is_edit															
     field_configs[field_configs.length] = {:field_type => 'CheckBox',
						:field_name => 'disabled'}
#end						
#============							

	build_form(program_function,field_configs,action,'program_function',caption,is_edit)

end
 
 
 def build_program_function_search_form(program_function,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:program_function_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["program_function_functional_area_name","program_function_program_name","program_function_name"])
	#Observers for search combos
	functional_area_name_observer  = {:updated_field_id => "program_name_cell",
					 :remote_method => 'program_function_functional_area_name_search_combo_changed',
					 :on_completed_js => search_combos_js["program_function_functional_area_name"]}

	session[:program_function_search_form][:functional_area_name_observer] = functional_area_name_observer

	program_name_observer  = {:updated_field_id => "name_cell",
					 :remote_method => 'program_function_program_name_search_combo_changed',
					 :on_completed_js => search_combos_js["program_function_program_name"]}

	session[:program_function_search_form][:program_name_observer] = program_name_observer

 
	functional_area_names = ProgramFunction.find_by_sql('select distinct functional_area_name from program_functions').map{|g|[g.functional_area_name]}
	functional_area_names.unshift("<empty>")
	if is_flat_search
		program_names = ProgramFunction.find_by_sql('select distinct program_name from program_functions').map{|g|[g.program_name]}
		program_names.unshift("<empty>")
		names = ProgramFunction.find_by_sql('select distinct name from program_functions').map{|g|[g.name]}
		names.unshift("<empty>")
		functional_area_name_observer = nil
		program_name_observer = nil
	else
		 program_names = ["Select a value from functional_area_name"]
		 names = ["Select a value from program_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name',
						:settings => {:list => functional_area_names},
						:observer => functional_area_name_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'program_name',
						:settings => {:list => program_names},
						:observer => program_name_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'name',
						:settings => {:list => names}}
 
	build_form(program_function,field_configs,action,'program_function',caption,false)

end



 def build_program_function_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'display_name'}
	column_configs[3] = {:field_type => 'text',:field_name => 'program_name'}
  column_configs[4] = {:field_type => 'text',:field_name => 'position'}
  column_configs[5] = {:field_type => 'text',:field_name => 'func_area_url_component'}
  column_configs[6] = {:field_type => 'text',:field_name => 'prog_url_component'}
	column_configs[7] = {:field_type => 'text',:field_name => 'functional_area_name'}
  column_configs[8] = {:field_type => 'text',:field_name => 'url_param'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit program_function',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_program_function',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete program_function',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_program_function',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
