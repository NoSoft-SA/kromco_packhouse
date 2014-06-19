module ChangeControl::SystemHelper
 
 
 def build_system_form(system,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:system_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'system_name'}

	build_form(system,field_configs,action,'system',caption,is_edit)

end
 
 
 def build_system_search_form(system,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:system_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	system_names = System.find_by_sql('select distinct system_name from systems').map{|g|[g.system_name]}
	system_names.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'system_name',
						:settings => {:list => system_names}}

	build_form(system,field_configs,action,'system',caption,false)

end



 def build_system_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'system_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit system',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_system',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete system',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_system',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
