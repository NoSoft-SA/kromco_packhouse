module Tools::PackGroupsCountsConfigHelper
 
 
 def build_pack_groups_counts_config_form(pack_groups_counts_config,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:pack_groups_counts_config_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: standard_counts
	combos_js_for_standard_counts = gen_combos_clear_js_for_combos(["pack_groups_counts_config_commodity_code","pack_groups_counts_config_standard_size_count_value","pack_groups_counts_config_size_code"])
	#Observers for combos representing the key fields of fkey table: standard_count_id
	
	commodity_code_observer  = {:updated_field_id => "standard_size_count_value_cell",
					 :remote_method => 'pack_groups_counts_config_commodity_code_changed',
					 :on_completed_js => combos_js_for_standard_counts ["pack_groups_counts_config_commodity_code"]}

	session[:pack_groups_counts_config_form][:commodity_code_observer] = commodity_code_observer

#	combo lists for table: standard_counts

	commodity_codes = nil 
	standard_size_count_values = ["Select a value from commodity_code"]
    size_codes = ["Select a value from commodity_code"]
	commodity_codes = PackGroupsCountsConfig.get_all_commodity_codes
	commodity_codes.unshift "<empty>"
	if pack_groups_counts_config == nil||is_create_retry
		 standard_size_count_values = ["Select a value from commodity_code"]
	else
		puts "its there"
		standard_size_count_values = PackGroupsCountsConfig.standard_size_count_values_for_commodity_code(pack_groups_counts_config.standard_count.commodity_code)if pack_groups_counts_config.standard_count
	    size_codes = Size.find_all_by_commodity_code(pack_groups_counts_config.size.commodity_code).map{|s|s.size_code} if pack_groups_counts_config.size
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'position'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (standard_count_id) on related table: standard_counts
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_value',
						:settings => {:list => standard_size_count_values}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (size_id) on related table: sizes
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'size_code',
						:settings => {:list => size_codes}}
 
	build_form(pack_groups_counts_config,field_configs,action,'pack_groups_counts_config',caption,is_edit)

end
 
 
 def build_pack_groups_counts_config_search_form(pack_groups_counts_config,action,caption,is_flat_search = nil)
    session[:pack_groups_counts_config_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: standard_counts
	combos_js_for_standard_counts = gen_combos_clear_js_for_combos(["pack_groups_counts_config_commodity_code","pack_groups_counts_config_standard_size_count_value","pack_groups_counts_config_size_code"])
	#Observers for combos representing the key fields of fkey table: standard_count_id
	
	commodity_code_observer  = {:updated_field_id => "standard_size_count_value_cell",
					 :remote_method => 'pack_groups_counts_config_commodity_code_changed',
					 :on_completed_js => combos_js_for_standard_counts ["pack_groups_counts_config_commodity_code"]}

	session[:pack_groups_counts_config_form][:commodity_code_observer] = commodity_code_observer

#	combo lists for table: standard_counts

	commodity_codes = nil 
	standard_size_count_values = ["Select a value from commodity_code"]
    size_codes = ["Select a value from commodity_code"]
	commodity_codes = PackGroupsCountsConfig.get_all_commodity_codes
	commodity_codes.unshift "<empty>"
	if pack_groups_counts_config == nil||is_create_retry
		 standard_size_count_values = ["Select a value from commodity_code"]
	else
		puts "its there"
		standard_size_count_values = PackGroupsCountsConfig.standard_size_count_values_for_commodity_code(pack_groups_counts_config.standard_count.commodity_code)if pack_groups_counts_config.standard_count
	    size_codes = Size.find_all_by_commodity_code(pack_groups_counts_config.size.commodity_code).map{|s|s.size_code} if pack_groups_counts_config.size
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_value',
						:settings => {:list => standard_size_count_values}}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'size_code',
						:settings => {:list => size_codes}}
 
	build_form(pack_groups_counts_config,field_configs,action,'pack_groups_counts_config',caption,false)

end


 def build_pack_groups_counts_config_grid(data_set,can_edit,can_delete)

    require File.dirname(__FILE__) + "/../../../app/helpers/tools/pack_groups_plugin.rb"

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'standard_size_count_value'}
	column_configs[1] = {:field_type => 'text',:field_name => 'size_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'position'}
	column_configs[3] = {:field_type => 'text',:field_name => 'commodity_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit pack_groups_counts_config',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_pack_groups_counts_config',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete pack_groups_counts_config',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_pack_groups_counts_config',
				:id_column => 'id'}}
	end
	#PackGroupsConfigPlugins
 return get_data_grid(data_set,column_configs,PackGroupsConfigPlugins::PackGroupsConfigGridPlugin.new)
end

end
