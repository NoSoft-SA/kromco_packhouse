module Fg::PortHelper
 
 
 def build_port_form(port,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:port_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'port_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'port_name'}

    field_configs[2] = {:field_type => 'TextField',
						:field_name => 'region_code'}

    field_configs[3] = {:field_type => 'TextField',
						:field_name => 'country_code'}


	build_form(port,field_configs,action,'port',caption,is_edit)

end
 
 
 def build_port_search_form(port,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:port_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	port_codes = Port.find_by_sql('select distinct port_code from ports').map{|g|[g.port_code]}
	port_codes.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'port_code',
						:settings => {:list => port_codes}}

	build_form(port,field_configs,action,'port',caption,false)

end



 def build_port_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'port_code',:col_width=>165}
	column_configs[1] = {:field_type => 'text',:field_name => 'port_name',:col_width=>210}
  column_configs[2] = {:field_type => 'text',:field_name => 'region_code',:col_width=>136}
  column_configs[3] = {:field_type => 'text',:field_name => 'country_code',:col_width=>118}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit port',:col_width=>70,
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_port',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete port',:col_width=>98,
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_port',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
