module ChangeControl::SubsystemHelper
 
 
 def build_subsystem_form(subsystem,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:subsystem_form]= Hash.new
	system_names = System.find_by_sql('select distinct system_name from systems').map{|g|[g.system_name]}
	system_names.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'subsystem_name'}

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (system_id) on related table: systems
#	-----------------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'system_name',
						:settings => {:list => system_names}}

 
	build_form(subsystem,field_configs,action,'subsystem',caption,is_edit)

end
 
 
 def build_subsystem_search_form(subsystem,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:subsystem_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	subsystem_names = Subsystem.find_by_sql('select distinct subsystem_name from subsystems').map{|g|[g.subsystem_name]}
	subsystem_names.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'subsystem_name',
						:settings => {:list => subsystem_names}}

	build_form(subsystem,field_configs,action,'subsystem',caption,false)

end



 def build_subsystem_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'subsystem_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'system_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit subsystem',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_subsystem',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete subsystem',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_subsystem',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
