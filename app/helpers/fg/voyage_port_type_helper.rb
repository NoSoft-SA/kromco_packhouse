module Fg::VoyagePortTypeHelper
 
 
 def build_voyage_port_type_form(voyage_port_type,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:voyage_port_type_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'voyage_port_type_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'voyage_port_type_description'}

	build_form(voyage_port_type,field_configs,action,'voyage_port_type',caption,is_edit)

end
 
 
 def build_voyage_port_type_search_form(voyage_port_type,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:voyage_port_type_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	voyage_port_type_codes = VoyagePortType.find_by_sql('select distinct voyage_port_type_code from voyage_port_types').map{|g|[g.voyage_port_type_code]}
	voyage_port_type_codes.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'voyage_port_type_code',
						:settings => {:list => voyage_port_type_codes}}

	build_form(voyage_port_type,field_configs,action,'voyage_port_type',caption,false)

end



 def build_voyage_port_type_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'voyage_port_type_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'voyage_port_type_description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit voyage_port_type',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_voyage_port_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete voyage_port_type',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_voyage_port_type',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
