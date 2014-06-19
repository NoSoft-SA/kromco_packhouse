module ChangeControl::AffectedObjectTypeHelper
 
 
 def build_affected_object_type_form(affected_object_type,action,caption,is_edit = nil,is_create_retry = nil)

	system_names = nil 
	subsystem_names = nil 
 
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'affected_object_type_name'}
						
	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'technology_name'}


 
	build_form(affected_object_type,field_configs,action,'affected_object_type',caption,is_edit)

end
 
 
 def build_affected_object_type_search_form(affected_object_type,action,caption,is_flat_search = nil)

 
     affected_object_type_names = AffectedObjectType.find(:all).map{|m|m.affected_object_type_name}
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	
 
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'affected_object_type_name',
						:settings => {:list => affected_object_type_names}}
 
	build_form(affected_object_type,field_configs,action,'affected_object_type',caption,false)

end



 def build_affected_object_type_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'affected_object_type_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'technology_name'}
	
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit affected_object_type',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_affected_object_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete affected_object_type',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_affected_object_type',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
