module RawMaterials::SprayProgramHelper
 
 
 def build_spray_program_form(spray_program,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:spray_program_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'spray_program_code'}

	build_form(spray_program,field_configs,action,'spray_program',caption,is_edit)

end
 
 
 def build_spray_program_search_form(spray_program,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:spray_program_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	spray_program_codes = SprayProgram.find_by_sql('select distinct spray_program_code from spray_programs').map{|g|[g.spray_program_code]}
	spray_program_codes.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'spray_program_code',
						:settings => {:list => spray_program_codes}}

	build_form(spray_program,field_configs,action,'spray_program',caption,false)

end



 def build_spray_program_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'spray_program_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit spray_program',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_spray_program',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete spray_program',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_spray_program',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
