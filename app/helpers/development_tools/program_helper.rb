module DevelopmentTools::ProgramHelper
 
 
 def build_program_form(program,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:program_form]= Hash.new
	functional_area_names = FunctionalArea.find_by_sql('select distinct functional_area_name from functional_areas').map{|g|[g.functional_area_name]}
	functional_area_names.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'program_name'}

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (functional_area_id) on related table: functional_areas
#	-----------------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name',
						:settings => {:list => functional_area_names}}

 
	build_form(program,field_configs,action,'program',caption,is_edit)

end
 
 
 def build_program_search_form(program,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:program_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["program_program_name","program_functional_area_name"])
	#Observers for search combos
	program_name_observer  = {:updated_field_id => "functional_area_name_cell",
					 :remote_method => 'program_program_name_search_combo_changed',
					 :on_completed_js => search_combos_js["program_program_name"]}

	session[:program_search_form][:program_name_observer] = program_name_observer

 
	program_names = Program.find_by_sql('select distinct program_name from programs').map{|g|[g.program_name]}
	program_names.unshift("<empty>")
	if is_flat_search
		functional_area_names = Program.find_by_sql('select distinct functional_area_name from programs').map{|g|[g.functional_area_name]}
		functional_area_names.unshift("<empty>")
		program_name_observer = nil
	else
		 functional_area_names = ["Select a value from program_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'program_name',
						:settings => {:list => program_names},
						:observer => program_name_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name',
						:settings => {:list => functional_area_names}}
 
	build_form(program,field_configs,action,'program',caption,false)

end



 def build_program_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'program_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'functional_area_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit program',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_program',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete program',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_program',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
