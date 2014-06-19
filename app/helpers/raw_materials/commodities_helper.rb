module RawMaterials::CommoditiesHelper
 
 
 def build_commodity_group_form(commodity_group,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:commodity_group_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'commodity_group_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'commodity_group_description'}

	build_form(commodity_group,field_configs,action,'commodity_group',caption,is_edit)

end
 
 
 def build_commodity_group_search_form(commodity_group,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:commodity_group_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["commodity_group_commodity_group_code"])
	#Observers for search combos
 
	commodity_group_codes = CommodityGroup.find_by_sql('select distinct commodity_group_code from commodity_groups').map{|g|[g.commodity_group_code]}
	commodity_group_codes.unshift("<empty>")
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
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_group_codes}}
 
	build_form(commodity_group,field_configs,action,'commodity_group',caption,false)

end



 def build_commodity_group_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'commodity_group_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'commodity_group_description'}

#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit commodity_group',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_commodity_group',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete commodity_group',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_commodity_group',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 #================
 #Commodities code
 #================
 
 def build_commodity_form(commodity,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:commodity_form]= Hash.new
	commodity_group_codes = CommodityGroup.find_by_sql('select distinct commodity_group_code from commodity_groups').map{|g|[g.commodity_group_code]}
	commodity_group_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'commodity_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'commodity_description_long'}

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'commodity_description_short'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (commodity_group_id) on related table: commodity_groups
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_group_codes}}

   field_configs[4] = {:field_type => 'CheckBox',
						:field_name => 'grower_commitment_required'}
 
	build_form(commodity,field_configs,action,'commodity',caption,is_edit)

end
 
 
 def build_commodity_search_form(commodity,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:commodity_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["commodity_commodity_code"])
	#Observers for search combos
 
	#commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
	commodity_groups = Commodity.find_by_sql('select distinct commodity_group_code from commodities').map{|g|[g.commodity_group_code]}
	commodity_groups.unshift("<empty>")
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
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_groups}}
 
	build_form(commodity,field_configs,action,'commodity',caption,false)

end



 def build_commodity_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'commodity_group_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'commodity_description_long'}
	column_configs[3] = {:field_type => 'text',:field_name => 'commodity_description_short'}
  column_configs[4] = {:field_type => 'text',:field_name => 'grower_commitment_required'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit commodity',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_commodity',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete commodity',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_commodity',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
