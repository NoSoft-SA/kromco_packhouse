module ChangeControl::ProjectHelper
 
 
 def build_project_form(project,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:project_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'project_name'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'description'}

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'status'}

	build_form(project,field_configs,action,'project',caption,is_edit)

end
 
 
 def build_project_search_form(project,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:project_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["project_project_name"])
	#Observers for search combos
 
	project_names = Project.find_by_sql('select distinct project_name from projects').map{|g|[g.project_name]}
	project_names.unshift("<empty>")
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
						:field_name => 'project_name',
						:settings => {:list => project_names}}
 
	build_form(project,field_configs,action,'project',caption,false)

end



 def build_project_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'project_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'status'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit project',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_project',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete project',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_project',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
