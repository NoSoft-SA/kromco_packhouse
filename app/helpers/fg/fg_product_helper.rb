module Products::FgProductHelper
 
 #=================
 #EXTENDED FG CODE
 #=================
 
 def build_extended_fg_form(extended_fg,action,caption,is_edit = nil,is_create_retry = nil)

    fg_codes = FgProduct.find(:all,:order => "fg_product_code").map{|m|[m.fg_product_code]}
    fg_marks = FgMark.find(:all,:order => "fg_mark_code").map{|m|[m.fg_mark_code]}
    orgs = Organization.get_all_by_role("MARKETER")
	orgs.unshift("<empty>")
    
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'extended_fg_code'}
	 
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'fg_code',
						:settings => {:list => fg_codes}}

	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'fg_mark_code',
						:settings => {:list => fg_marks}}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'units_per_carton'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'tu_nett_mass'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'tu_gross_mass'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'ri_diameter_range'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'ri_weight_range'}
						
	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'ru_description'}
						
	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'old_fg_code'}

	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'marketing_org_code',
						:settings => {:list => orgs}}
						
	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'commodity_code'}
											
	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_value'}
						
	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}

   field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'external_party_product_code'}

   field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'price'}

	build_form(extended_fg,field_configs,action,'extended_fg',caption,is_edit)

end
 
 
 def build_extended_fg_search_form(extended_fg,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:extended_fg_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["extended_fg_fg_code","extended_fg_fg_mark_code","extended_fg_units_per_carton"])
	#Observers for search combos
	fg_code_observer  = {:updated_field_id => "fg_mark_code_cell",
					 :remote_method => 'extended_fg_fg_code_search_combo_changed',
					 :on_completed_js => search_combos_js["extended_fg_fg_code"]}

	session[:extended_fg_search_form][:fg_code_observer] = fg_code_observer

	fg_mark_code_observer  = {:updated_field_id => "units_per_carton_cell",
					 :remote_method => 'extended_fg_fg_mark_code_search_combo_changed',
					 :on_completed_js => search_combos_js["extended_fg_fg_mark_code"]}

	session[:extended_fg_search_form][:fg_mark_code_observer] = fg_mark_code_observer

 
	fg_codes = ExtendedFg.find_by_sql('select distinct fg_code from extended_fgs').map{|g|[g.fg_code]}
	fg_codes.unshift("<empty>")
	if is_flat_search
		fg_mark_codes = ExtendedFg.find_by_sql('select distinct fg_mark_code from extended_fgs').map{|g|[g.fg_mark_code]}
		fg_mark_codes.unshift("<empty>")
		units_per_cartons = ExtendedFg.find_by_sql('select distinct units_per_carton from extended_fgs').map{|g|[g.units_per_carton]}
		units_per_cartons.unshift("<empty>")
		fg_code_observer = nil
		fg_mark_code_observer = nil
		old_fgs = ExtendedFg.find_by_sql('select distinct old_fg_code from extended_fgs').map{|g|[g.old_fg_code]}
	    old_fgs.unshift("<empty>")
	    orgs = Organization.get_all_by_role("MARKETER")
	    orgs.unshift("<empty>")
	    commodities = ExtendedFg.find_by_sql("select distinct commodity_code from extended_fgs").map{|c|[c.commodity_code]}
	    commodities.unshift("<empty>")
	    size_counts = ExtendedFg.find_by_sql("select distinct standard_size_count_value from extended_fgs").map{|s|[s.standard_size_count_value]}
	    size_counts.unshift("<empty>")
	    grades = ExtendedFg.find_by_sql("select distinct grade_code from extended_fgs").map{|g|[g.grade_code]}
	    grades.unshift("<empty>")
	    
	else
		 fg_mark_codes = ["Select a value from fg_code"]
		 units_per_cartons = ["Select a value from fg_mark_code"]
	end
	
	@extended_fg = ExtendedFg.new
	extended_fg = @extended_fg
	#extended_fg.fg_code = "<empty>"
	#extended_fg.fg_mark_code = "<empty>"
	#extended_fg.units_per_carton = "<empty>"
	#extended_fg.old_fg_code = "<empty>"
	#extended_fg.marketing_org_code = "<empty>"
	#extended_fg.commodity_code = "<empty>"
	#extended_fg.grade_code = "<empty>"
	#extended_fg.standard_size_count_value = "<empty>"
	
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'TextField',
						:field_name => 'extended_fg_code'}
	
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'fg_code',
						:settings => {:list => fg_codes},
						:observer => fg_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'fg_mark_code',
						:settings => {:list => fg_mark_codes},
						:observer => fg_mark_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'units_per_carton',
						:settings => {:list => units_per_cartons}}
						
	if is_flat_search
	  field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'old_fg_code',
						:settings => {:list => old_fgs}}
						
	  field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'marketing_org_code',
						:settings => {:list => orgs}}
						
	 field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodities}}
						
	 field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grades}}
						
	 field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_value',
						:settings => {:list => size_counts}}
						
						
				
	end
	
 
	build_form(extended_fg,field_configs,action,'extended_fg',caption,false)

end



 def build_extended_fg_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'extended_fg_code'}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'external_party_product_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'fg_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'fg_mark_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'old_fg_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'units_per_carton'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'tu_gross_mass'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'tu_nett_mass'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'ri_diameter_range'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'ri_weight_range'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'marketing_org_code'}

#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit extended_fg',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_extended_fg',
				:id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'clone extended_fg',
			:settings =>
				 {:link_text => 'clone',
				:target_action => 'clone_extended_fg',
				:id_column => 'id'}}
    
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete extended_fg',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_extended_fg',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 #======================
 #FG MARKS CODE
 #======================
  def build_fg_mark_form(fg_mark,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:fg_mark_form]= Hash.new
	marks = Mark.find(:all,:order => "mark_code").map{|m|[m.mark_code]}
	
	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	 
	 field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'fg_mark_code'}
						
						
	 field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'ri_mark_code',
						:settings => {:list => marks}}

	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'ru_mark_code',
						:settings => {:list => marks}}

	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'tu_mark_code',
						:settings => {:list => marks}}

	

	build_form(fg_mark,field_configs,action,'fg_mark',caption,is_edit)

end
 
 
 def build_fg_mark_search_form(fg_mark,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:fg_mark_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["fg_mark_ri_mark_code","fg_mark_ru_mark_code","fg_mark_tu_mark_code","fg_mark_fg_mark_code"])
	#Observers for search combos
	ri_mark_code_observer  = {:updated_field_id => "ru_mark_code_cell",
					 :remote_method => 'fg_mark_ri_mark_code_search_combo_changed',
					 :on_completed_js => search_combos_js["fg_mark_ri_mark_code"]}

	session[:fg_mark_search_form][:ri_mark_code_observer] = ri_mark_code_observer

	ru_mark_code_observer  = {:updated_field_id => "tu_mark_code_cell",
					 :remote_method => 'fg_mark_ru_mark_code_search_combo_changed',
					 :on_completed_js => search_combos_js["fg_mark_ru_mark_code"]}

	session[:fg_mark_search_form][:ru_mark_code_observer] = ru_mark_code_observer

	tu_mark_code_observer  = {:updated_field_id => "fg_mark_code_cell",
					 :remote_method => 'fg_mark_tu_mark_code_search_combo_changed',
					 :on_completed_js => search_combos_js["fg_mark_tu_mark_code"]}

	session[:fg_mark_search_form][:tu_mark_code_observer] = tu_mark_code_observer

 
	ri_mark_codes = FgMark.find_by_sql('select distinct ri_mark_code from fg_marks').map{|g|[g.ri_mark_code]}
	ri_mark_codes.unshift("<empty>")
	if is_flat_search
		ru_mark_codes = FgMark.find_by_sql('select distinct ru_mark_code from fg_marks').map{|g|[g.ru_mark_code]}
		ru_mark_codes.unshift("<empty>")
		tu_mark_codes = FgMark.find_by_sql('select distinct tu_mark_code from fg_marks').map{|g|[g.tu_mark_code]}
		tu_mark_codes.unshift("<empty>")
		fg_mark_codes = FgMark.find_by_sql('select distinct fg_mark_code from fg_marks').map{|g|[g.fg_mark_code]}
		fg_mark_codes.unshift("<empty>")
		ri_mark_code_observer = nil
		ru_mark_code_observer = nil
		tu_mark_code_observer = nil
	else
		 ru_mark_codes = ["Select a value from ri_mark_code"]
		 tu_mark_codes = ["Select a value from ru_mark_code"]
		 fg_mark_codes = ["Select a value from tu_mark_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'ri_mark_code',
						:settings => {:list => ri_mark_codes},
						:observer => ri_mark_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'ru_mark_code',
						:settings => {:list => ru_mark_codes},
						:observer => ru_mark_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'tu_mark_code',
						:settings => {:list => tu_mark_codes},
						:observer => tu_mark_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'fg_mark_code',
						:settings => {:list => fg_mark_codes}}
 
	build_form(fg_mark,field_configs,action,'fg_mark',caption,false)

end



 def build_fg_mark_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'ri_mark_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'ru_mark_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'tu_mark_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'fg_mark_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit fg_mark',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_fg_mark',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete fg_mark',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_fg_mark',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 
 
 #===============================
 #FG PRODUCT CODE
 #===============================
 
 def view_fg_product(fg_product,action = nil)
 
   action = "view_paging_handler" if !action
   
     field_configs = Array.new
	 field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'fg_product_code'}
						
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'item_pack_product_code'}

	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'unit_pack_product_code'}
    
    field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'carton_pack_product_code'}

	build_form(fg_product,field_configs,action,'fg_product',"back")
 
 
 
 end
 
 
 def build_fg_product_form(fg_product,action,caption,is_edit = nil,is_create_retry = nil)

  
  upc_codes = UnitPackProduct.find(:all).map{|u|u.unit_pack_product_code}
  ipc_codes = ItemPackProduct.find(:all).map{|u|u.item_pack_product_code}
  cpc_codes = CartonPackProduct.find(:all).map{|u|u.carton_pack_product_code}
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
						
	field_configs[0] = {:field_type => 'DropDownField',
						:field_name => 'item_pack_product_code',
						:settings => {:list => ipc_codes}}

	field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'unit_pack_product_code',
						:settings => {:list => upc_codes}}
    
    field_configs[2] = {:field_type => 'DropDownField',
						:field_name => 'carton_pack_product_code',
						:settings => {:list => cpc_codes}}

	build_form(fg_product,field_configs,action,'fg_product',caption,is_edit)

end
 
 
 def build_fg_product_search_form(fg_product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:fg_product_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["fg_product_item_pack_product_code","fg_product_unit_pack_product_code","fg_product_carton_pack_product_code"])
	#Observers for search combos
	item_pack_product_code_observer  = {:updated_field_id => "unit_pack_product_code_cell",
					 :remote_method => 'fg_product_item_pack_product_code_search_combo_changed',
					 :on_completed_js => search_combos_js["fg_product_item_pack_product_code"]}

	session[:fg_product_search_form][:item_pack_product_code_observer] = item_pack_product_code_observer

	unit_pack_product_code_observer  = {:updated_field_id => "carton_pack_product_code_cell",
					 :remote_method => 'fg_product_unit_pack_product_code_search_combo_changed',
					 :on_completed_js => search_combos_js["fg_product_unit_pack_product_code"]}

	session[:fg_product_search_form][:unit_pack_product_code_observer] = unit_pack_product_code_observer

 
	item_pack_product_codes = FgProduct.find_by_sql('select distinct item_pack_product_code from fg_products').map{|g|[g.item_pack_product_code]}
	item_pack_product_codes.unshift("<empty>")
	if is_flat_search
		unit_pack_product_codes = FgProduct.find_by_sql('select distinct unit_pack_product_code from fg_products').map{|g|[g.unit_pack_product_code]}
		unit_pack_product_codes.unshift("<empty>")
		carton_pack_product_codes = FgProduct.find_by_sql('select distinct carton_pack_product_code from fg_products').map{|g|[g.carton_pack_product_code]}
		carton_pack_product_codes.unshift("<empty>")
		item_pack_product_code_observer = nil
		unit_pack_product_code_observer = nil
	else
		 unit_pack_product_codes = ["Select a value from item_pack_product_code"]
		 carton_pack_product_codes = ["Select a value from unit_pack_product_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'item_pack_product_code',
						:settings => {:list => item_pack_product_codes},
						:observer => item_pack_product_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'unit_pack_product_code',
						:settings => {:list => unit_pack_product_codes},
						:observer => unit_pack_product_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'carton_pack_product_code',
						:settings => {:list => carton_pack_product_codes}}
 
	build_form(fg_product,field_configs,action,'fg_product',caption,false)

end



 def build_fg_product_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'fg_product_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'item_pack_product_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'unit_pack_product_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'carton_pack_product_code'}
#	----------------------
#	define action columns
#	----------------------
	
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view fg_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_fg_product',
				:id_column => 'id'}}
	
	
 return get_data_grid(data_set,column_configs)
end

end
