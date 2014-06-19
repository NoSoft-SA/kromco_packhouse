module Security::DepartmentHelper
 
 
 def build_department_form(department,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:department_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'department_name'}

	build_form(department,field_configs,action,'department',caption,is_edit)

end
 
 
 def build_department_search_form(department,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:department_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
	department_names = Department.find_by_sql('select distinct department_name from departments').map{|g|[g.department_name]}
	department_names.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'department_name',
						:settings => {:list => department_names}}

	build_form(department,field_configs,action,'department',caption,false)

end



 def build_department_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'department_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit department',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_department',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete department',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_department',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
