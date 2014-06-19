module RawMaterials::TrackIndicatorHelper
 
 
 #=============
 #OLD PACK CODE
 #=============
 
def build_old_pack_form(old_pack,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:old_pack_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'old_pack_code'}

	build_form(old_pack,field_configs,action,'old_pack',caption,is_edit)

end
 
 
 def build_old_pack_search_form(old_pack,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:old_pack_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["old_pack_old_pack_code"])
	#Observers for search combos
 
	old_pack_codes = OldPack.find_by_sql('select distinct old_pack_code from old_packs').map{|g|[g.old_pack_code]}
	old_pack_codes.unshift("<empty>")
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
						:field_name => 'old_pack_code',
						:settings => {:list => old_pack_codes}}
 
	build_form(old_pack,field_configs,action,'old_pack',caption,false)

end



 def build_old_pack_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'old_pack_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit old_pack',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_old_pack',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete old_pack',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_old_pack',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 #================
 #BASIC PACK CODE
 #================
 def build_basic_pack_form(basic_pack,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:basic_pack_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'basic_pack_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'short_code'}

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'length'}

	field_configs[3] = {:field_type => 'TextField',
						:field_name => 'width'}

	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'height'}
            
            field_configs[5] = {:field_type => 'TextField',
						:field_name => 'weight'}

	build_form(basic_pack,field_configs,action,'basic_pack',caption,is_edit)

end
 
 
 def build_basic_pack_search_form(basic_pack,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:basic_pack_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["basic_pack_basic_pack_code"])
	#Observers for search combos
 
	basic_pack_codes = BasicPack.find_by_sql('select distinct basic_pack_code from basic_packs').map{|g|[g.basic_pack_code]}
	basic_pack_codes.unshift("<empty>")
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
						:field_name => 'basic_pack_code',
						:settings => {:list => basic_pack_codes}}
 
	build_form(basic_pack,field_configs,action,'basic_pack',caption,false)

end

 def build_basic_pack_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'basic_pack_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'short_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'length'}
	column_configs[3] = {:field_type => 'text',:field_name => 'width'}
	column_configs[4] = {:field_type => 'text',:field_name => 'height'}
  column_configs[5] = {:field_type => 'text',:field_name => 'weight'}

#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit basic_pack',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_basic_pack',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete basic_pack',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_basic_pack',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 #=========
 #GTIN CODE
 #=========
 def build_gtin_form(gtin,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:gtin_form]= Hash.new
	mark_codes = Mark.find_by_sql('select distinct mark_code from marks').map{|g|[g.mark_code]}
	mark_codes.unshift("<empty>")
	grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map{|g|[g.grade_code]}
	grade_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: standard_size_counts
	combos_js_for_standard_size_counts = gen_combos_clear_js_for_combos(["gtin_commodity_code","gtin_old_pack_code","gtin_actual_count"])
	#Observers for combos representing the key fields of fkey table: standard_size_count_id
	short_descriptions = Organization.find_by_sql('select distinct short_description from organizations').map{|g|[g.short_description]}
	short_descriptions.unshift("<empty>")
	target_market_names = TargetMarket.find_by_sql('select distinct target_market_name from target_markets').map{|g|[g.target_market_name]}
	target_market_names.unshift("<empty>")
	
	on_complete_js = "\n img = document.getElementById('img_gtin_organization_code');"
	on_complete_js += "\n if(img != null)img.style.display = 'none';"
	
	#Observers for search combos
	org_observer  = {:updated_field_id => "ajax_distributor_cell",
					 :remote_method => 'gtin_org_combo_changed',
					 :on_completed_js => on_complete_js}
	
	commodity_code_observer  = {:updated_field_id => "old_pack_code_cell",
					 :remote_method => 'gtin_commodity_code_changed',
					 :on_completed_js => combos_js_for_standard_size_counts["gtin_commodity_code"]}

	session[:gtin_form][:commodity_code_observer] = commodity_code_observer

	old_pack_code_observer  = {:updated_field_id => "actual_count_cell",
					 :remote_method => 'gtin_old_pack_code_changed',
					 :on_completed_js => combos_js_for_standard_size_counts ["gtin_old_pack_code"]}

	session[:gtin_form][:old_pack_code_observer] = old_pack_code_observer
	
	
	js = "\n img = document.getElementById('img_gtin_mark_code');"
	js += "\n if(img != null)img.style.display = 'none';"
	
	mark_observer  = {:updated_field_id => "brand_code_cell",
					 :remote_method => 'mark_code_changed',
					 :on_completed_js => js}

#	combo lists for table: standard_size_counts

	commodity_codes = nil 
	old_pack_codes = nil 
	actual_counts = nil 
	marketing_variety_codes = nil
	target_markets = nil
	inventory_codes = nil
 
	commodity_codes = Gtin.get_all_commodity_codes
	commodity_codes.unshift("<empty>")
	if gtin == nil||is_create_retry
		 old_pack_codes = ["Select a value from commodity_code"]
		 actual_counts = ["Select a value from old_pack_code"]
		 marketing_variety_codes = ["Select a value from commodity code"]
		 target_markets = ["Select a value from organization code"]
		 inventory_codes = ["Select a value from organization code"]
	else
		old_pack_codes = Gtin.old_pack_codes_for_commodity_code(gtin.commodity_code)
		actual_counts = Gtin.actual_counts_for_old_pack_code_and_commodity_code(gtin.old_pack_code, gtin.commodity_code)
	    marketing_variety_codes = MarketingVariety.find_all_by_commodity_code(gtin.commodity_code).map{|c|[c.marketing_variety_code]}
	    target_markets = TargetMarket.get_all_by_org(gtin.organization_code)
	    inventory_codes = InventoryCode.get_all_by_org(gtin.organization_code)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'gtin_code'}

	field_configs[1] = {:field_type => 'DateField',
						:field_name => 'date_from'}

	field_configs[2] = {:field_type => 'DateField',
						:field_name => 'date_to'}

#   ----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (organization_id) on related table: organizations
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'organization_code',
						:settings => {:list => short_descriptions,
						              :label_caption => "org code"},
						:observer => org_observer}

	field_configs[4] = {:field_type => 'DropDownField',
						:field_name => 'target_market_code',
						:settings => {:list => target_markets}}

	field_configs[5] = {:field_type => 'DropDownField',
						:field_name => 'inventory_code',
						:settings => {:list => inventory_codes}}


	field_configs[6] = {:field_type => 'TextField',
						:field_name => 'transaction_number'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (mark_id) on related table: marks
#	----------------------------------------------------------------------------------------------
	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'mark_code',
						:settings => {:list => mark_codes},
						:observer => mark_observer}
    
    field_configs[8] = {:field_type => 'LabelField',
						:field_name => 'brand_code'}
						
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (grade_id) on related table: grades
#	----------------------------------------------------------------------------------------------
	field_configs[9] =  {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grade_codes}}
 


#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (standard_size_count_id) on related table: standard_size_counts
#	----------------------------------------------------------------------------------------------
	field_configs[10] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
						
	field_configs[11] = {:field_type => 'DropDownField',
						:field_name => 'marketing_variety_code',
						:settings => {:list => marketing_variety_codes}}
 
	field_configs[12] =  {:field_type => 'DropDownField',
						:field_name => 'old_pack_code',
						:settings => {:list => old_pack_codes},
						:observer => old_pack_code_observer}
 
	field_configs[13] =  {:field_type => 'DropDownField',
						:field_name => 'actual_count',
						:settings => {:list => actual_counts}}
 
    field_configs[14] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}
 
	build_form(gtin,field_configs,action,'gtin',caption,is_edit)

end
 
 
 def build_gtin_search_form(gtin,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:gtin_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["gtin_organization_code","gtin_commodity_code","gtin_marketing_variety_code","gtin_old_pack_code","gtin_mark_code","gtin_actual_count","gtin_grade_code","gtin_inventory_code"])
	#Observers for search combos
	organization_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'gtin_organization_code_search_combo_changed',
					 :on_completed_js => search_combos_js["gtin_organization_code"]}
	session[:gtin_search_form][:organization_code_observer] = organization_code_observer

	commodity_code_observer  = {:updated_field_id => "marketing_variety_code_cell",
					 :remote_method => 'gtin_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["gtin_commodity_code"]}

	session[:gtin_search_form][:commodity_code_observer] = commodity_code_observer

	marketing_variety_code_observer  = {:updated_field_id => "old_pack_code_cell",
					 :remote_method => 'gtin_marketing_variety_code_search_combo_changed',
					 :on_completed_js => search_combos_js["gtin_marketing_variety_code"]}

	session[:gtin_search_form][:marketing_variety_code_observer] = marketing_variety_code_observer

	old_pack_code_observer  = {:updated_field_id => "mark_code_cell",
					 :remote_method => 'gtin_old_pack_code_search_combo_changed',
					 :on_completed_js => search_combos_js["gtin_old_pack_code"]}

	session[:gtin_search_form][:old_pack_code_observer] = old_pack_code_observer

	mark_code_observer  = {:updated_field_id => "actual_count_cell",
					 :remote_method => 'gtin_mark_code_search_combo_changed',
					 :on_completed_js => search_combos_js["gtin_mark_code"]}

	session[:gtin_search_form][:mark_code_observer] = mark_code_observer

	actual_count_observer  = {:updated_field_id => "grade_code_cell",
					 :remote_method => 'gtin_actual_count_search_combo_changed',
					 :on_completed_js => search_combos_js["gtin_actual_count"]}

	session[:gtin_search_form][:actual_count_observer] = actual_count_observer

	grade_code_observer  = {:updated_field_id => "inventory_code_cell",
					 :remote_method => 'gtin_grade_code_search_combo_changed',
					 :on_completed_js => search_combos_js["gtin_grade_code"]}

	session[:gtin_search_form][:grade_code_observer] = grade_code_observer

 
	organization_codes = Gtin.find_by_sql('select distinct organization_code from gtins').map{|g|[g.organization_code]}
	organization_codes.unshift("<empty>")
	if is_flat_search
		commodity_codes = Gtin.find_by_sql('select distinct commodity_code from gtins').map{|g|[g.commodity_code]}
		commodity_codes.unshift("<empty>")
		marketing_variety_codes = Gtin.find_by_sql('select distinct marketing_variety_code from gtins').map{|g|[g.marketing_variety_code]}
		marketing_variety_codes.unshift("<empty>")
		old_pack_codes = Gtin.find_by_sql('select distinct old_pack_code from gtins').map{|g|[g.old_pack_code]}
		old_pack_codes.unshift("<empty>")
		mark_codes = Gtin.find_by_sql('select distinct mark_code from gtins').map{|g|[g.mark_code]}
		mark_codes.unshift("<empty>")
		actual_counts = Gtin.find_by_sql('select distinct actual_count from gtins').map{|g|[g.actual_count]}
		actual_counts.unshift("<empty>")
		grade_codes = Gtin.find_by_sql('select distinct grade_code from gtins').map{|g|[g.grade_code]}
		grade_codes.unshift("<empty>")
		inventory_codes = Gtin.find_by_sql('select distinct inventory_code from gtins').map{|g|[g.inventory_code]}
		inventory_codes.unshift("<empty>")
		organization_code_observer = nil
		commodity_code_observer = nil
		marketing_variety_code_observer = nil
		old_pack_code_observer = nil
		mark_code_observer = nil
		actual_count_observer = nil
		grade_code_observer = nil
	else
		 commodity_codes = ["Select a value from organization_code"]
		 marketing_variety_codes = ["Select a value from commodity_code"]
		 old_pack_codes = ["Select a value from marketing_variety_code"]
		 mark_codes = ["Select a value from old_pack_code"]
		 actual_counts = ["Select a value from mark_code"]
		 grade_codes = ["Select a value from actual_count"]
		 inventory_codes = ["Select a value from grade_code"]
	end
	
	brand_codes = Gtin.find_by_sql('select distinct brand_code from gtins').map{|g|[g.brand_code]}
    brand_codes.unshift("<empty>")
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'organization_code',
						:settings => {:list => organization_codes,
						              :label_caption => "org code"},
						:observer => organization_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'marketing_variety_code',
						:settings => {:list => marketing_variety_codes},
						:observer => marketing_variety_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'old_pack_code',
						:settings => {:list => old_pack_codes},
						:observer => old_pack_code_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'mark_code',
						:settings => {:list => mark_codes},
						:observer => mark_code_observer}
 
	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'actual_count',
						:settings => {:list => actual_counts},
						:observer => actual_count_observer}
 
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grade_codes},
						:observer => grade_code_observer}
 
	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'inventory_code',
						:settings => {:list => inventory_codes}}
 
 
    field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'brand_code',
						:settings => {:list => brand_codes}}
						
	build_form(gtin,field_configs,action,'gtin',caption,false)

end



 def build_gtin_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'gtin_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'date_from'}
	column_configs[2] = {:field_type => 'text',:field_name => 'date_to'}
	column_configs[3] = {:field_type => 'text',:field_name => 'organization_code',:column_caption => "org code"}
	column_configs[4] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'old_pack_code'}
	column_configs[6] = {:field_type => 'text',:field_name => 'grade_code'}
	column_configs[7] = {:field_type => 'text',:field_name => 'mark_code'}
	column_configs[8] = {:field_type => 'text',:field_name => 'inventory_code'}
	column_configs[9] = {:field_type => 'text',:field_name => 'target_market_code'}
	column_configs[10] = {:field_type => 'text',:field_name => 'transaction_number'}
	column_configs[11] = {:field_type => 'text',:field_name => 'marketing_variety_code'}
	column_configs[12] = {:field_type => 'text',:field_name => 'actual_count'}
	column_configs[7] = {:field_type => 'text',:field_name => 'brand_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit gtin',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_gtin',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete gtin',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_gtin',
				:id_column => 'id'}}
	end

   column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'target markets',
			:settings =>
				 {:link_text => 'target markets',
				 :host_and_port =>request.host_with_port.to_s,
				 :controller =>request.path_parameters['controller'].to_s ,
				 :target_action => 'gtin_target_markets',
				 :id_column => 'id'}}
    
 return get_data_grid(data_set,column_configs)
end

 def build_gtin_target_markets_grid(data_set,actions)
    column_configs = Array.new
#puts "is hash = " + data_set.kind_of?(Hash).to_s
   if(data_set[0].kind_of?(Hash))
      data_set[0].keys.each do |key|
        column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key}
      end
   else
#      puts " data_set[0].class.name = " + data_set[0].class.name
     data_set[0].attributes.keys.each do |key|
        column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key}
      end
   end

    if(actions)
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'remove',
      :settings =>
         {:link_text => 'remove',
        :target_action => 'remove_gtin_target_market',
        :id_column => 'id'}}
    end
    
    return get_data_grid(data_set,column_configs,nil,true)
  end

 def build_new_gtin_target_market_from(gtin_target_market,action,caption,gtin_code)
   target_market_codes = TargetMarket.find_by_sql("select distinct target_market_name  from target_markets").map{|t|[t.target_market_name]}
   field_configs = Array.new
   field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'gtin_code',
            :settings=>{:static_value=>gtin_code, :show_label=>true}
            }
   field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'target_market_code',
						:settings => {:list => target_market_codes}}

	 build_form(gtin_target_market,field_configs,action,'gtin_target_market',caption,nil)
 end

 
 #======================
 #TRACK INDICATOR CODE
 #======================
 def build_track_indicator_form(track_indicator,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:track_indicator_form]= Hash.new
	 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["track_indicator_commodity_group_code","track_indicator_commodity_code","track_indicator_rmt_variety_code"])
	#Observers for search combos
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'track_indicator_commodity_group_combo_changed',
					 :on_completed_js => search_combos_js["track_indicator_commodity_group_code"]}

	session[:track_indicator_form][:commodity_group_code_observer] = commodity_group_code_observer

	commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
					 :remote_method => 'track_indicator_commodity_combo_changed',
					 :on_completed_js => search_combos_js["track_indicator_commodity_code"]}

	session[:track_indicator_form][:commodity_code_observer] = commodity_code_observer

  
   commodity_group_codes = RmtVariety.get_all_commodity_group_codes
	if track_indicator == nil||is_create_retry
		 commodity_codes = ["Select a value from commodity_group_code"]
		 rmt_variety_codes = ["Select a value from commodity_code"]
		 
	else
	    if track_indicator.commodity_group_code
		  commodity_codes = RmtVariety.commodity_codes_for_commodity_group_code(track_indicator.commodity_group_code)
	    else
	      commodity_codes = ["Select a value from commodity_group_code"]
	    end
	   
	   if track_indicator.rmt_variety_code
	     rmt_variety_codes = RmtVariety.find_by_sql("select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{track_indicator.commodity_code}'").map{|g|[g.rmt_variety_code]}
	   else
	     rmt_variety_codes = ["Select a value from commodity_code"]
	   end
		
	end

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	 
 
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
						
						
	field_configs[3] = {:field_type => 'TextField',
						:field_name => 'track_indicator_code'}

	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'description'}

  field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'group_1_code',
						:settings => {:list => ['FOR PACKING','NOT FOR PACKING']}}

  field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'group_2_code',
						:settings => {:list => ['ALTERNATIVE MARKETING','CANNING','FOR PACKING',
                                  'JUICE','NOT FOR PACKING','PRIVATE STORAGE','SCRAPPED'
                          ]}}



	build_form(track_indicator,field_configs,action,'track_indicator',caption,is_edit)

end
 
 
 def build_track_indicator_search_form(track_indicator,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:track_indicator_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["track_indicator_track_indicator_code"])
	#Observers for search combos
 
	track_indicator_codes = TrackIndicator.find_by_sql('select distinct track_indicator_code from track_indicators').map{|g|[g.track_indicator_code]}
	track_indicator_codes.unshift("<empty>")
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
						:field_name => 'track_indicator_code',
						:settings => {:list => track_indicator_codes}}
 
	build_form(track_indicator,field_configs,action,'track_indicator',caption,false)

end



 def build_track_indicator_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'track_indicator_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'rmt_variety_code'}
  column_configs[4] = {:field_type => 'text',:field_name => 'group_1_code'}
  column_configs[5] = {:field_type => 'text',:field_name => 'group_2_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit track_indicator',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_track_indicator',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete track_indicator',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_track_indicator',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end



#========================================================================================================
#TRACK SLMS INDICATOR CODE/Happymore
#========================================================================================================


def build_track_slms_indicator_form(track_slms_indicator,action,caption,is_edit = nil,is_create_retry = nil)

#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:track_slms_indicator_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	combos_js_for_slms = gen_combos_clear_js_for_combos(["track_slms_indicator_variety_type", "track_slms_indicator_commodity_code"])
	
	on_complete_js_variety = "\n img = document.getElementById('img_track_slms_indicator_variety_type');"
	on_complete_js_variety += "\n if(img != null) img.style.display = 'none';"
	
	variety_type_observer = {:updated_field_id =>"marketing_variety_code_cell",
	                         :remote_method => 'track_slms_indicator_variety_type_changed',
	                         :on_completed_js =>combos_js_for_slms["track_slms_indicator_variety_type"]}
	                         
	on_complete_js = "\n img = document.getElementById('img_track_slms_indicator_commodity_code');"
	on_complete_js += "\n if(img != null) img.style.display = 'none';"
	
	commodity_code_observer = {:updated_field_id =>"ajax_distributor_cell",
	                         :remote_method => 'track_slms_indicator_commodity_code_changed',
	                         :on_completed_js =>on_complete_js}
	                         
	session[:track_slms_indicator_form][:variety_type_observer] = variety_type_observer
	session[:track_slms_indicator_form][:commodity_code_observer] = commodity_code_observer
	
	track_indicator_type_codes = TrackIndicatorType.get_all_track_indicator_type_codes
	track_indicator_type_codes.unshift("<empty>")
	
	variety_types = ["marketing_variety","rmt_variety" ]
	
	commodity_codes = Commodity.find_by_sql("select commodity_code from commodities").map{|g| [g.commodity_code]}
	commodity_codes.unshift("<empty>")
	if is_create_retry == false #track_slms_indicator ==nil #||is_create_retry 
	   variety_codes = ["Select a value from commodity_code"]
	   season_codes = ["Select a value from commodity_code"]     
	else
	   if track_slms_indicator.commodity_code
	       #commodity_codes = Commodity.find_by_sql("select commodity_code from commodities").map{|g| [g.commodity_code]}
	       if track_slms_indicator.variety_type
    	       if track_slms_indicator.variety_type == "marketing_variety"
    	           variety_codes = MarketingVariety.find_by_sql("select distinct marketing_variety_code from marketing_varieties where commodity_code = '#{track_slms_indicator.commodity_code}'").map{|g| [g.marketing_variety_code]}
    	       else
    	           variety_codes = RmtVariety.find_by_sql("select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{track_slms_indicator.commodity_code}'").map{|g| [g.rmt_variety_code]}
    	       end
	       end
	        season_codes = Season.get_season_codes_for_commodity_code(track_slms_indicator.commodity_code)
	   else
    	   variety_codes = ["Select a value from commodity_code"]
    	   season_codes = ["Select a value from commodity_code"]   
	   end
	end

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	 
	 field_configs[0] = {:field_type =>'DropDownField',
	                     :field_name =>'track_indicator_type_code',
	                     :settings =>{:list =>track_indicator_type_codes}}
	                     
	 field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'variety_type',
						:settings =>{:list =>variety_types},
						:observer =>variety_type_observer}
						
	 field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings =>{:list =>commodity_codes},
						:observer =>commodity_code_observer}
						
	 field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'variety_code',
						:settings =>{:list =>variety_codes}}
						
	 field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'season_code',
						:settings =>{:list =>season_codes}}
	   
	 field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'track_slms_indicator_code'}
						
	 field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'track_slms_indicator_description'}

	 field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'date_from'}

	 field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'date_to'}
						
	 field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'track_variable_1'}

	 field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'track_variable_2'}
						
	 
  if (is_edit || is_create_retry) && track_slms_indicator.variety_type != "marketing_variety" #!track_slms_indicator||
     marketing_variety_codes = MarketingVariety.find_by_sql("select distinct marketing_variety_code from marketing_varieties where commodity_code='#{track_slms_indicator.commodity_code}'").map{|g| [g.marketing_variety_code]}
     field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'marketing_variety_code',
						:settings =>{:list =>marketing_variety_codes}}
   else
    	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
    						:field_name => 'marketing_variety_code',
    						:settings=>{:css_class =>'marketing_variety_code'}}
     end
     
     field_configs[field_configs.length()] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}
						
	 field_configs[field_configs.length()] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor2',
						:non_db_field => true}

	 build_form(track_slms_indicator,field_configs,action,'track_slms_indicator',caption,is_edit)

end
 
 
 def build_track_slms_indicator_search_form(track_slms_indicator,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:track_slms_indicator_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["track_slms_indicator_track_indicator_type_code", "track_slms_indicator_variety_type", "track_slms_indicator_commodity_code", "track_slms_indicator_variety_code", "track_slms_indicator_season_code", "track_slms_indicator_track_slms_indicator_code"])
	
	#Observers for search combos
	track_indicator_type_code_observer = {:updated_field_id => "variety_type_cell",
					 :remote_method => 'track_slms_indicator_track_indicator_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["track_slms_indicator_track_indicator_type_code"]}
					 
	session[:track_slms_indicator_search_form][:track_indicator_type_code_observer] = track_indicator_type_code_observer
	
	variety_type_observer = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'track_slms_indicator_variety_type_search_combo_changed',
					 :on_completed_js => search_combos_js["track_slms_indicator_variety_type"]}
					 
	session[:track_slms_indicator_search_form][:variety_type_observer] = variety_type_observer
	
	commodity_code_observer = {:updated_field_id => "variety_code_cell",
					 :remote_method => 'track_slms_indicator_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["track_slms_indicator_commodity_code"]}
					 
	session[:track_slms_indicator_search_form][:commodity_code_observer] = commodity_code_observer
	
	variety_code_observer = {:updated_field_id => "season_code_cell",
					 :remote_method => 'track_slms_indicator_variety_code_search_combo_changed',
					 :on_completed_js => search_combos_js["track_slms_indicator_variety_code"]}
					 
	session[:track_slms_indicator_search_form][:variety_code_observer] = variety_code_observer
	
	season_code_observer = {:updated_field_id => "track_slms_indicator_code_cell",
					 :remote_method => 'track_slms_indicator_season_code_search_combo_changed',
					 :on_completed_js => search_combos_js["track_slms_indicator_season_code"]}
					 
	session[:track_slms_indicator_search_form][:season_code_observer] = season_code_observer
	
	track_indicator_type_codes = TrackSlmsIndicator.find_by_sql('select distinct track_indicator_type_code from track_slms_indicators').map{|g| [g.track_indicator_type_code]}
	track_indicator_type_codes.unshift("<empty>")
	if is_flat_search
	   variety_types = TrackSlmsIndicator.find_by_sql('select distinct variety_type from track_slms_indicators').map{|g|[g.variety_type]}
	   variety_types.unshift("<empty>")
	   commodity_codes = TrackSlmsIndicator.find_by_sql('select distinct commodity_code from track_slms_indicators').map{|g|[g.commodity_code]}
	   commodity_codes.unshift("<empty>")
	   variety_codes = TrackSlmsIndicator.find_by_sql('select distinct variety_code from track_slms_indicators').map{|g|[g.variety_code]}
	   variety_codes.unshift("<empty>")
	   season_codes = TrackSlmsIndicator.find_by_sql('select distinct season_code from track_slms_indicators').map{|g|[g.season_code]}
	   season_codes.unshift("<empty>")
	   track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql('select distinct track_slms_indicator_code from track_slms_indicators').map{|g|[g.track_slms_indicator_code]}
	   track_slms_indicator_codes.unshift("<empty>")
	   track_indicator_type_code_observer = nil
	   variety_type_observer = nil
	   commodity_code_observer = nil
	   variety_code_observer = nil
	   season_code_observer = nil
	else
	   variety_types = ["Select a value from track_indicator_type_code"]
	   commodity_codes = ["Select a value from variety_type"]
	   variety_codes = ["Select a value from commodity_code"]
	   season_codes = ["Select a value from variety_code"]
	   track_slms_indicator_codes = ["Select a value from season_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'track_indicator_type_code',
						:settings => {:list => track_indicator_type_codes},
						:observer => track_indicator_type_code_observer}
						
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                      						:field_name => 'variety_type',
                      						:settings => {:list => variety_types},
                      						:observer => variety_type_observer}
                      						
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                      						:field_name => 'commodity_code',
                      						:settings => {:list => commodity_codes},
                      						:observer => commodity_code_observer}
                      						
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                      						:field_name => 'variety_code',
                      						:settings => {:list => variety_codes},
                      						:observer => variety_code_observer}
                      						
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                      						:field_name => 'season_code',
                      						:settings => {:list => season_codes},
                      						:observer => season_code_observer}
                      						
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                      						:field_name => 'track_slms_indicator_code',
                      						:settings => {:list => track_slms_indicator_codes}}

	build_form(track_slms_indicator,field_configs,action,'track_slms_indicator',caption,false)

end



 def build_track_slms_indicator_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'track_slms_indicator_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'track_slms_indicator_description'}
	column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>'track_indicator_type_code'}
	column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>'variety_type'}
	column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>'commodity_code'}
	column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>'variety_code'}
	column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>'season_code'}
  column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>'track_variable_1'}
  column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>'track_variable_2'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'date_from'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'date_to'}
	
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_track_slms_indicator',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_track_slms_indicator',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

#==================================================================================================
#END TRACK SLMS INDICATORS/Happymore
#==================================================================================================
end
