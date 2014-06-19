module RawMaterials::VarietiesHelper
 
 
 #===============================
 #VARIETY (INPUT OUTPUT MAP) CODE
 #===============================
 
  def build_variety_form(variety,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:variety_form]= Hash.new
	
	#generate javascript for the on_complete ajax event for each combo for fk table: commodities
	combos_js_for_commodities = gen_combos_clear_js_for_combos(["variety_commodity_group_code","variety_commodity_code"])
	#Observers for combos representing the key fields of fkey table: commodity_id
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'variety_commodity_group_code_changed',
					 :on_completed_js => combos_js_for_commodities ["variety_commodity_group_code"]}

	on_complete_js = "\n img = document.getElementById('img_variety_commodity_code');"
	on_complete_js += "\n if(img != null)img.style.display = 'none';"
	
    commodity_code_observer  = {:updated_field_id => "ajax_distributor_cell",
					 :remote_method => 'variety_commodity_code_changed',
					 :on_completed_js => on_complete_js }
					 
					 
	session[:variety_form][:commodity_group_code_observer] = commodity_group_code_observer
    session[:variety_form][:commodity_code_observer] = commodity_code_observer
    
    
#	combo lists for table: commodities

	commodity_group_codes = nil 
	commodity_codes = nil 
	marketing_variety_codes = nil
	rmt_variety_codes = nil
 
	commodity_group_codes = Variety.get_all_commodity_group_codes
	if variety == nil||is_create_retry
		 commodity_codes = ["Select a value from commodity_group_code"]
		 rmt_variety_codes = ["Select a value from commodity code"]
		 marketing_variety_codes = ["Select a value from commodity code"]
	else
		commodity_codes = Variety.commodity_codes_for_commodity_group_code(variety.commodity.commodity_group_code)
	    rmt_variety_codes = Variety.find_by_sql("select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{variety.commodity_code}'").map{|v|[v.rmt_variety_code]}
	    marketing_variety_codes = Variety.find_by_sql("select distinct marketing_variety_code from marketing_varieties where commodity_code = '#{variety.commodity_code}'").map{|v|[v.marketing_variety_code]}
	end
	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (commodity_id) on related table: commodities
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
    field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_code',
						:settings => {:list => rmt_variety_codes}}
						
						
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'marketing_variety_code',
						:settings => {:list => marketing_variety_codes}}
						
	 field_configs[4] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}

	build_form(variety,field_configs,action,'variety',caption,is_edit)

end
 
 
 def build_variety_search_form(variety,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:variety_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["variety_commodity_group_code","variety_commodity_code","variety_rmt_variety_code"])
	#Observers for search combos
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'variety_commodity_group_code_search_combo_changed',
					 :on_completed_js => search_combos_js["variety_commodity_group_code"]}

	session[:variety_search_form][:commodity_group_code_observer] = commodity_group_code_observer

	commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
					 :remote_method => 'variety_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["variety_commodity_code"]}

	session[:variety_search_form][:commodity_code_observer] = commodity_code_observer

 
	commodity_group_codes = Variety.find_by_sql('select distinct commodity_group_code from rmt_varieties').map{|g|[g.commodity_group_code]}
	commodity_group_codes.unshift("<empty>")
	if is_flat_search
		commodity_codes = Variety.find_by_sql('select distinct commodity_code from rmt_varieties').map{|g|[g.commodity_code]}
		commodity_codes.unshift("<empty>")
		variety_codes = Variety.find_by_sql('select distinct rmt_variety_code from varieties').map{|g|[g.rmt_variety_code]}
		variety_codes.unshift("<empty>")
		commodity_group_code_observer = nil
		commodity_code_observer = nil
	else
		 commodity_codes = ["Select a value from commodity_group_code"]
		 variety_codes = ["Select a value from commodity_code"]
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
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_code',
						:settings => {:list => variety_codes}}
 
	build_form(variety,field_configs,action,'variety',caption,false)

end



 def build_variety_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'commodity_group_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'rmt_variety_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'marketing_variety_code'}


#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit variety',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_variety',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete variety',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_variety',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 #================
 #RMT VARIETY CODE
 #================
 
  def build_rmt_variety_form(rmt_variety,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:rmt_variety_form]= Hash.new
	
	#generate javascript for the on_complete ajax event for each combo for fk table: commodities
	combos_js_for_commodities = gen_combos_clear_js_for_combos(["rmt_variety_commodity_group_code","rmt_variety_commodity_code","rmt_variety_variety_group_code"])
	#Observers for combos representing the key fields of fkey table: commodity_id
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'rmt_variety_commodity_group_code_changed',
					 :on_completed_js => combos_js_for_commodities ["rmt_variety_commodity_group_code"]}

  commodity_code_observer  = {:updated_field_id => "variety_group_code_cell",
					 :remote_method => 'rmt_variety_commodity_code_changed',
					 :on_completed_js => combos_js_for_commodities ["rmt_variety_commodity_code"]}

	session[:rmt_variety_form][:commodity_group_code_observer] = commodity_group_code_observer

  session[:rmt_variety_form][:commodity_code_observer] = commodity_code_observer

#	combo lists for table: commodities

	commodity_group_codes = nil 
	commodity_codes = nil 
 
	commodity_group_codes = RmtVariety.get_all_commodity_group_codes
	if rmt_variety == nil||is_create_retry
		 commodity_codes = ["Select a value from commodity_group_code"]
	else
		commodity_codes = RmtVariety.commodity_codes_for_commodity_group_code(rmt_variety.commodity.commodity_group_code)
	end
	
	variety_groups = VarietyGroup.find_all().map{|v|v.variety_group_code}
	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'rmt_variety_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (commodity_id) on related table: commodities
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
            :observer => commodity_code_observer}
						
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'variety_group_code',
						:settings => {:list => variety_groups}}
 
 
	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'drench_rmt'}

  field_configs[5] = {:field_type => 'TextField',
						:field_name => 'sample_percentage'}

  field_configs[6] = {:field_type => 'TextField',
						:field_name => 'quality_test_code'}

  field_configs[7] = {:field_type => 'TextField',
						:field_name => 'rmt_variety_description'}

	build_form(rmt_variety,field_configs,action,'rmt_variety',caption,is_edit)

end
 
 
 def build_rmt_variety_search_form(rmt_variety,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:rmt_variety_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["rmt_variety_commodity_group_code","rmt_variety_commodity_code","rmt_variety_marketing_variety_code"])
	#Observers for search combos
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'rmt_variety_commodity_group_code_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_variety_commodity_group_code"]}

	session[:rmt_variety_search_form][:commodity_group_code_observer] = commodity_group_code_observer

	commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
					 :remote_method => 'rmt_variety_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_variety_commodity_code"]}

	session[:rmt_variety_search_form][:commodity_code_observer] = commodity_code_observer

 
	commodity_group_codes = RmtVariety.find_by_sql('select distinct commodity_group_code from rmt_varieties').map{|g|[g.commodity_group_code]}
	commodity_group_codes.unshift("<empty>")
	if is_flat_search
		commodity_codes = RmtVariety.find_by_sql('select distinct commodity_code from rmt_varieties').map{|g|[g.commodity_code]}
		commodity_codes.unshift("<empty>")
		rmt_variety_codes = RmtVariety.find_by_sql('select distinct rmt_variety_code from rmt_varieties').map{|g|[g.rmt_variety_code]}
		rmt_variety_codes.unshift("<empty>")
		commodity_group_code_observer = nil
		commodity_code_observer = nil
	else
		 commodity_codes = ["Select a value from commodity_group_code"]
		 rmt_variety_codes = ["Select a value from commodity_code"]
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
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_code',
						:settings => {:list => rmt_variety_codes}}
 
	build_form(rmt_variety,field_configs,action,'rmt_variety',caption,false)

end



 def build_rmt_variety_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'commodity_group_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'rmt_variety_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'rmt_variety_description'}
  column_configs[4] = {:field_type => 'text',:field_name => 'drench_rmt'}
  column_configs[5] = {:field_type => 'text',:field_name => 'sample_percentage'}
  column_configs[6] = {:field_type => 'text',:field_name => 'quality_test_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit rmt_variety',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_rmt_variety',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete rmt_variety',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_rmt_variety',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 #===================================
 #MARKETING VARIETY CODE
 #===================================
 def build_marketing_variety_form(marketing_variety,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:marketing_variety_form]= Hash.new
	commodity_codes = VarietyGroup.find_by_sql('select distinct commodity_code from variety_groups').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: commodities
	combos_js_for_commodities = gen_combos_clear_js_for_combos(["marketing_variety_commodity_group_code","marketing_variety_commodity_code"])
	#Observers for combos representing the key fields of fkey table: commodity_id
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'marketing_variety_commodity_group_code_changed',
					 :on_completed_js => combos_js_for_commodities ["marketing_variety_commodity_group_code"]}

	session[:marketing_variety_form][:commodity_group_code_observer] = commodity_group_code_observer

#	combo lists for table: commodities

	commodity_group_codes = nil 
	commodity_codes = nil 
 
	commodity_group_codes = MarketingVariety.get_all_commodity_group_codes
	if marketing_variety == nil||is_create_retry
		 commodity_codes = ["Select a value from commodity_group_code"]
	else
		commodity_codes = MarketingVariety.commodity_codes_for_commodity_group_code(marketing_variety.commodity.commodity_group_code)
	end
	
	variety_groups = VarietyGroup.find_all().map{|v|v.variety_group_code}
	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'marketing_variety_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (commodity_id) on related table: commodities
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes}}
												
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'variety_group_code',
						:settings => {:list => variety_groups}}
 
 
	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'marketing_variety_description'}

	build_form(marketing_variety,field_configs,action,'marketing_variety',caption,is_edit)

end
 
 
 def build_marketing_variety_search_form(marketing_variety,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:marketing_variety_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["marketing_variety_commodity_group_code","marketing_variety_commodity_code","marketing_variety_marketing_variety_code"])
	#Observers for search combos
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'marketing_variety_commodity_group_code_search_combo_changed',
					 :on_completed_js => search_combos_js["marketing_variety_commodity_group_code"]}

	session[:marketing_variety_search_form][:commodity_group_code_observer] = commodity_group_code_observer

	commodity_code_observer  = {:updated_field_id => "marketing_variety_code_cell",
					 :remote_method => 'marketing_variety_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["marketing_variety_commodity_code"]}

	session[:marketing_variety_search_form][:commodity_code_observer] = commodity_code_observer

 
	commodity_group_codes = MarketingVariety.find_by_sql('select distinct commodity_group_code from marketing_varieties').map{|g|[g.commodity_group_code]}
	commodity_group_codes.unshift("<empty>")
	if is_flat_search
		commodity_codes = MarketingVariety.find_by_sql('select distinct commodity_code from marketing_varieties').map{|g|[g.commodity_code]}
		commodity_codes.unshift("<empty>")
		marketing_variety_codes = MarketingVariety.find_by_sql('select distinct marketing_variety_code from marketing_varieties').map{|g|[g.marketing_variety_code]}
		marketing_variety_codes.unshift("<empty>")
		commodity_group_code_observer = nil
		commodity_code_observer = nil
	else
		 commodity_codes = ["Select a value from commodity_group_code"]
		 marketing_variety_codes = ["Select a value from commodity_code"]
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
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
#	field_configs[2] =  {:field_type => 'DropDownField',
#						:field_name => 'marketing_variety_code',
#						:settings => {:list => marketing_variety_codes}}
 
	build_form(marketing_variety,field_configs,action,'marketing_variety',caption,false)

end



 def build_marketing_variety_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'commodity_group_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'marketing_variety_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'marketing_variety_description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit marketing_variety',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_marketing_variety',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete marketing_variety',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_marketing_variety',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
