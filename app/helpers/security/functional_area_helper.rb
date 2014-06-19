module Security::FunctionalAreaHelper
 
 
 def build_functional_area_form(functional_area,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:functional_area_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	 field_configs[0] = {:field_type => 'TextField',
						:field_name => 'functional_area_name'}

     field_configs[1] = {:field_type => 'TextField',
						:field_name => 'display_name'}
						
	 field_configs[2] = {:field_type => 'TextField',
						:field_name => 'class_name'}
#=============
#Luks' Code ==
#=============
     field_configs[3] = {:field_type => 'CheckBox',
						:field_name => 'is_non_web_program'}
																		
     field_configs[4] = {:field_type => 'CheckBox',
						:field_name => 'disabled'}
#============												
	build_form(functional_area,field_configs,action,'functional_area',caption,is_edit)

end
 
 
 def build_functional_area_search_form(functional_area,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:functional_area_search_form]= Hash.new 
	field_configs = Array.new
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	functional_area_names = FunctionalArea.find_by_sql('select distinct functional_area_name from functional_areas').map{|g|[g.functional_area_name]}
	functional_area_names.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name',
						:settings => {:list => functional_area_names}}

	build_form(functional_area,field_configs,action,'functional_area',caption,false)

end



 def build_functional_area_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'functional_area_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit functional_area',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_functional_area',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete functional_area',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_functional_area',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
