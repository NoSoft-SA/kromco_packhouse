module ChangeControl::AffectedObjectHelper
 
 
 def build_affected_object_form(affected_object,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:affected_object_form]= Hash.new
	affected_object_type_names = AffectedObjectType.find_by_sql('select distinct affected_object_type_name from affected_object_types').map{|g|[g.affected_object_type_name]}
	affected_object_type_names.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: subsystems
	combos_js_for_subsystems = gen_combos_clear_js_for_combos(["affected_object_system_name","affected_object_subsystem_name"])
	#Observers for combos representing the key fields of fkey table: subsystem_id


	system_name_observer  = {:updated_field_id => "subsystem_name_cell",
					 :remote_method => 'affected_object_system_name_changed',
					 :on_completed_js => combos_js_for_subsystems ["affected_object_system_name"]}

	session[:affected_object_form][:system_name_observer] = system_name_observer

#	combo lists for table: subsystems

	system_names = nil 
	subsystem_names = nil 
 
	system_names = AffectedObject.get_all_system_names
	if affected_object == nil||is_create_retry
		 subsystem_names = ["Select a value from system_name"]
	else
		subsystem_names = AffectedObject.subsystem_names_for_system_name(affected_object.subsystem.system_name)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'affected_object_name'}

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (affected_object_type_id) on related table: affected_object_types
#	-----------------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'affected_object_type_name',
						:settings => {:list => affected_object_type_names}}

 

 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (subsystem_id) on related table: subsystems
#	----------------------------------------------------------------------------------------------
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'system_name',
						:settings => {:list => system_names},
						:observer => system_name_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'subsystem_name',
						:settings => {:list => subsystem_names}}
 
	build_form(affected_object,field_configs,action,'affected_object',caption,is_edit)

end
 
 
 def build_affected_object_search_form(affected_object,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:affected_object_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["affected_object_system_name","affected_object_subsystem_name","affected_object_affected_object_type_name","affected_object_affected_object_name"])
	#Observers for search combos
	system_name_observer  = {:updated_field_id => "subsystem_name_cell",
					 :remote_method => 'affected_object_system_name_search_combo_changed',
					 :on_completed_js => search_combos_js["affected_object_system_name"]}

	session[:affected_object_search_form][:system_name_observer] = system_name_observer

	subsystem_name_observer  = {:updated_field_id => "affected_object_type_name_cell",
					 :remote_method => 'affected_object_subsystem_name_search_combo_changed',
					 :on_completed_js => search_combos_js["affected_object_subsystem_name"]}

	session[:affected_object_search_form][:subsystem_name_observer] = subsystem_name_observer

	affected_object_type_name_observer  = {:updated_field_id => "affected_object_name_cell",
					 :remote_method => 'affected_object_affected_object_type_name_search_combo_changed',
					 :on_completed_js => search_combos_js["affected_object_affected_object_type_name"]}

	session[:affected_object_search_form][:affected_object_type_name_observer] = affected_object_type_name_observer

 
	system_names = AffectedObject.find_by_sql('select distinct system_name from affected_objects').map{|g|[g.system_name]}
	system_names.unshift("<empty>")
	if is_flat_search
		subsystem_names = AffectedObject.find_by_sql('select distinct subsystem_name from affected_objects').map{|g|[g.subsystem_name]}
		subsystem_names.unshift("<empty>")
		affected_object_type_names = AffectedObject.find_by_sql('select distinct affected_object_type_name from affected_objects').map{|g|[g.affected_object_type_name]}
		affected_object_type_names.unshift("<empty>")
		affected_object_names = AffectedObject.find_by_sql('select distinct affected_object_name from affected_objects').map{|g|[g.affected_object_name]}
		affected_object_names.unshift("<empty>")
		system_name_observer = nil
		subsystem_name_observer = nil
		affected_object_type_name_observer = nil
	else
		 subsystem_names = ["Select a value from system_name"]
		 affected_object_type_names = ["Select a value from subsystem_name"]
		 affected_object_names = ["Select a value from affected_object_type_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'system_name',
						:settings => {:list => system_names},
						:observer => system_name_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'subsystem_name',
						:settings => {:list => subsystem_names},
						:observer => subsystem_name_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'affected_object_type_name',
						:settings => {:list => affected_object_type_names},
						:observer => affected_object_type_name_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'affected_object_name',
						:settings => {:list => affected_object_names}}
 
	build_form(affected_object,field_configs,action,'affected_object',caption,false)

end



 def build_affected_object_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'affected_object_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'affected_object_type_name'}
	column_configs[2] = {:field_type => 'text',:field_name => 'system_name'}
	column_configs[3] = {:field_type => 'text',:field_name => 'subsystem_name'}

#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit affected_object',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_affected_object',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete affected_object',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_affected_object',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
