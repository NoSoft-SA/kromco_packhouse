module RawMaterials::CountsHelper
 
 
 #==============
 #Size ref code
 #=============
 def build_size_ref_form(size_ref,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:size_ref_form]= Hash.new
	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'size_ref_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (commodity_id) on related table: commodities
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes}}
 
	build_form(size_ref,field_configs,action,'size_ref',caption,is_edit)

end
 
 
 def build_size_ref_search_form(size_ref,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:size_ref_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["size_ref_commodity_code","size_ref_size_ref_code"])
	#Observers for search combos
	commodity_code_observer  = {:updated_field_id => "size_ref_code_cell",
					 :remote_method => 'size_ref_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["size_ref_commodity_code"]}

	session[:size_ref_search_form][:commodity_code_observer] = commodity_code_observer

 
	commodity_codes = SizeRef.find_by_sql('select distinct commodity_code from size_refs').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
	if is_flat_search
		size_ref_codes = SizeRef.find_by_sql('select distinct size_ref_code from size_refs').map{|g|[g.size_ref_code]}
		size_ref_codes.unshift("<empty>")
		commodity_code_observer = nil
	else
		 size_ref_codes = ["Select a value from commodity_code"]
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
						:field_name => 'size_ref_code',
						:settings => {:list => size_ref_codes}}
 
	build_form(size_ref,field_configs,action,'size_ref',caption,false)

end



 def build_size_ref_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'size_ref_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'commodity_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit size_ref',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_size_ref',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete size_ref',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_size_ref',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 #======================
 #Size code
 #======================
 
 def build_size_form(size,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	on_complete_js = "\n img = document.getElementById('img_size_commodity_code');"
	on_complete_js += "\n if(img != null)img.style.display = 'none';"
	
    commodity_observer  = {:updated_field_id => "ajax_distributor_cell",
					 :remote_method => 'size_commodity_code_changed',
					 :on_completed_js => on_complete_js }
					 
	count_codes = nil
	if size == nil||is_create_retry
	  count_codes = ["select a value from commodity code"]	 
	else
	  count_codes = StandardCount.find_all_by_commodity_code(size.commodity_code).map{|c|[c.standard_count_value]}
	  count_codes.unshift("-1")
	end
	
	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'size_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'size_description'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (commodity_id) on related table: commodities
#	----------------------------------------------------------------------------------------------
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'equivalent_count_from',
						:settings => {:list => count_codes}}

	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'equivalent_count_to',
						:settings => {:list => count_codes}}
						
	field_configs[5] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}

	build_form(size,field_configs,action,'size',caption,is_edit)

end
 
 
 def build_size_search_form(size,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:size_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["size_commodity_code","size_size_code"])
	#Observers for search combos
	commodity_code_observer  = {:updated_field_id => "size_code_cell",
					 :remote_method => 'size_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["size_commodity_code"]}

	session[:size_search_form][:commodity_code_observer] = commodity_code_observer

 
	commodity_codes = Size.find_by_sql('select distinct commodity_code from sizes').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
	if is_flat_search
		size_codes = Size.find_by_sql('select distinct size_code from sizes').map{|g|[g.size_code]}
		size_codes.unshift("<empty>")
		commodity_code_observer = nil
	else
		 size_codes = ["Select a value from commodity_code"]
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
						:field_name => 'size_code',
						:settings => {:list => size_codes}}
 
	build_form(size,field_configs,action,'size',caption,false)

end



 def build_size_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'size_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'size_description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'equivalent_count_from'}
	column_configs[3] = {:field_type => 'text',:field_name => 'equivalent_count_to'}
	column_configs[4] = {:field_type => 'text',:field_name => 'commodity_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit size',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_size',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete size',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_size',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 #========================
 #Standard size count code
 #========================
 
 def build_standard_size_count_form(standard_size_count,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:standard_size_count_form]= Hash.new
	standard_count_values = StandardCount.find_by_sql('select distinct standard_count_value from standard_counts').map{|g|[g.standard_count_value]}
	standard_count_values.unshift("<empty>")
	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
	basic_pack_codes = BasicPack.find_by_sql('select distinct basic_pack_code from basic_packs').map{|g|[g.basic_pack_code]}
	basic_pack_codes.unshift("<empty>")
	old_pack_codes = OldPack.find_by_sql('select distinct old_pack_code from old_packs').map{|g|[g.old_pack_code]}
	old_pack_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'standard_size_count_description'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (commodity_id) on related table: commodities
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes}}
 
	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'diameter_mm'}


#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (old_pack_id) on related table: old_packs
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'old_pack_code',
						:settings => {:list => old_pack_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (standard_count_id) on related table: standard_counts
#	----------------------------------------------------------------------------------------------
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_value',
						:settings => {:list => standard_count_values}}
 

	field_configs[5] = {:field_type => 'TextField',
						:field_name => 'actual_count'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (basic_pack_id) on related table: basic_packs
#	----------------------------------------------------------------------------------------------
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'basic_pack_code',
						:settings => {:list => basic_pack_codes}}
 
	build_form(standard_size_count,field_configs,action,'standard_size_count',caption,is_edit)

end
 
 
 def build_standard_size_count_search_form(standard_size_count,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:standard_size_count_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["standard_size_count_commodity_code","standard_size_count_standard_size_count_value","standard_size_count_basic_pack_code","standard_size_count_actual_count"])
	#Observers for search combos
	commodity_code_observer  = {:updated_field_id => "standard_size_count_value_cell",
					 :remote_method => 'standard_size_count_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["standard_size_count_commodity_code"]}

	session[:standard_size_count_search_form][:commodity_code_observer] = commodity_code_observer

	standard_size_count_value_observer  = {:updated_field_id => "basic_pack_code_cell",
					 :remote_method => 'standard_size_count_standard_size_count_value_search_combo_changed',
					 :on_completed_js => search_combos_js["standard_size_count_standard_size_count_value"]}

	session[:standard_size_count_search_form][:standard_size_count_value_observer] = standard_size_count_value_observer

	basic_pack_code_observer  = {:updated_field_id => "actual_count_cell",
					 :remote_method => 'standard_size_count_basic_pack_code_search_combo_changed',
					 :on_completed_js => search_combos_js["standard_size_count_basic_pack_code"]}

	session[:standard_size_count_search_form][:basic_pack_code_observer] = basic_pack_code_observer

 
	commodity_codes = StandardSizeCount.find_by_sql('select distinct commodity_code from standard_size_counts').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
	if is_flat_search
		standard_size_count_values = StandardSizeCount.find_by_sql('select distinct standard_size_count_value from standard_size_counts').map{|g|[g.standard_size_count_value]}
		standard_size_count_values.unshift("<empty>")
		basic_pack_codes = StandardSizeCount.find_by_sql('select distinct basic_pack_code from standard_size_counts').map{|g|[g.basic_pack_code]}
		basic_pack_codes.unshift("<empty>")
		actual_counts = StandardSizeCount.find_by_sql('select distinct actual_count from standard_size_counts').map{|g|[g.actual_count]}
		actual_counts.unshift("<empty>")
		commodity_code_observer = nil
		standard_size_count_value_observer = nil
		basic_pack_code_observer = nil
	else
		 standard_size_count_values = ["Select a value from commodity_code"]
		 basic_pack_codes = ["Select a value from standard_size_count_value"]
		 actual_counts = ["Select a value from basic_pack_code"]
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
						:settings => {:list => standard_size_count_values},
						:observer => standard_size_count_value_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'basic_pack_code',
						:settings => {:list => basic_pack_codes},
						:observer => basic_pack_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'actual_count',
						:settings => {:list => actual_counts}}
 
	build_form(standard_size_count,field_configs,action,'standard_size_count',caption,false)

end



 def build_standard_size_count_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'standard_size_count_description'}
	column_configs[1] = {:field_type => 'text',:field_name => 'old_pack_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'diameter_mm'}
	column_configs[3] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[4] = {:field_type => 'text',:field_name => 'basic_pack_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'standard_size_count_value'}
	column_configs[6] = {:field_type => 'text',:field_name => 'actual_count'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit standard_size_count',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_standard_size_count',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete standard_size_count',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_standard_size_count',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 #===================
 #Standard count code
 #===================
 def build_standard_count_form(standard_count,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:standard_count_form]= Hash.new
	
	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (commodity_id) on related table: commodities
#	----------------------------------------------------------------------------------------------
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'standard_count_value'}
	
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes}}
											
	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'size_count_description'}


	field_configs[3] = {:field_type => 'TextField',
						:field_name => 'minimum_size_mm'}

	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'maximum_size_mm'}

	field_configs[5] = {:field_type => 'TextField',
						:field_name => 'average_size_mm'}

	field_configs[6] = {:field_type => 'TextField',
						:field_name => 'minimum_weight_gm'}

	field_configs[7] = {:field_type => 'TextField',
						:field_name => 'maximum_weight_gm'}

	field_configs[8] = {:field_type => 'TextField',
						:field_name => 'average_weight_gm'}

	field_configs[9] = {:field_type => 'TextField',
						:field_name => 'count_interval_group'}

	field_configs[10] = {:field_type => 'TextField',
						:field_name => 'marketing_size_range_mm'}

	field_configs[11] = {:field_type => 'TextField',
						:field_name => 'marketing_weight_range'}

	field_configs[12] = {:field_type => 'DateField',
						:field_name => 'date_from'}

	field_configs[13] = {:field_type => 'DateField',
						:field_name => 'date_to'}

	
	build_form(standard_count,field_configs,action,'standard_count',caption,is_edit)

end
 
 
 def build_standard_count_search_form(standard_count,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:standard_count_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["standard_count_standard_count_value"])
	#Observers for search combos
 
	#standard_count_values = StandardCount.find_by_sql('select distinct standard_count_value from standard_counts').map{|g|[g.standard_count_value]}
	commodities = StandardCount.find_by_sql('select distinct commodity_code from standard_counts').map{|g|[g.commodity_code]}
	commodities.unshift("<empty>")
	#standard_count_values.unshift("<empty>")
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
						:field_name => 'commodity_code',
						:settings => {:list => commodities}}
 
	build_form(standard_count,field_configs,action,'standard_count',caption,false)

end



 def build_standard_count_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'size_count_description'}
	column_configs[1] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'minimum_size_mm'}
	column_configs[3] = {:field_type => 'text',:field_name => 'maximum_size_mm'}
	column_configs[4] = {:field_type => 'text',:field_name => 'average_size_mm'}
	column_configs[5] = {:field_type => 'text',:field_name => 'minimum_weight_gm'}
	column_configs[6] = {:field_type => 'text',:field_name => 'maximum_weight_gm'}
	column_configs[7] = {:field_type => 'text',:field_name => 'average_weight_gm'}
	column_configs[8] = {:field_type => 'text',:field_name => 'count_interval_group'}
	column_configs[9] = {:field_type => 'text',:field_name => 'marketing_size_range_mm'}
	column_configs[10] = {:field_type => 'text',:field_name => 'marketing_weight_range'}
	column_configs[11] = {:field_type => 'text',:field_name => 'date_from'}
	column_configs[12] = {:field_type => 'text',:field_name => 'date_to'}
	column_configs[13] = {:field_type => 'text',:field_name => 'standard_count_value'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit standard_count',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_standard_count',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete standard_count',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_standard_count',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
