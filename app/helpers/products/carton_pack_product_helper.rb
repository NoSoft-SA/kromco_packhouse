module Products::CartonPackProductHelper
 
  
 def build_carton_pack_product_form(carton_pack_product,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:carton_pack_product_form]= Hash.new
	carton_pack_style_codes = CartonPackStyle.find_by_sql('select distinct carton_pack_style_code from carton_pack_styles').map{|g|[g.carton_pack_style_code]}
	carton_pack_style_codes.unshift("<empty>")
	type_codes = CartonPackType.find_by_sql('select distinct type_code from carton_pack_types').map{|g|[g.type_code]}
	type_codes.unshift("<empty>")
	basic_pack_codes = BasicPack.find_by_sql('select distinct basic_pack_code from basic_packs').map{|g|[g.basic_pack_code]}
	basic_pack_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'carton_pack_product_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (carton_pack_type_id) on related table: carton_pack_types
#	----------------------------------------------------------------------------------------------
	if !is_edit
	    field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'type_code',
						:settings => {:list => type_codes}}
 
     #	----------------------------------------------------------------------------------------------
     #	Combo fields to represent foreign key (basic_pack_id) on related table: basic_packs
     #	----------------------------------------------------------------------------------------------
	    field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'basic_pack_code',
						:settings => {:list => basic_pack_codes}}
 
     #	----------------------------------------------------------------------------------------------------
     #	Combo field to represent foreign key (carton_pack_style_id) on related table: carton_pack_styles
     #	-----------------------------------------------------------------------------------------------------
	    field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'carton_pack_style_code',
						:settings => {:list => carton_pack_style_codes}}
    
	     field_configs[4] = {:field_type => 'TextField',
						:field_name => 'height'}
	else
	 
	 field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'type_code'}
						
	 field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'basic_pack_code'}
						
	 field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'carton_pack_style_code'}
						
	 field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'height'}
						
	
	end
						
	
	field_configs[5] = {:field_type => 'TextField',
						:field_name => 'nett_mass'}

	build_form(carton_pack_product,field_configs,action,'carton_pack_product',caption,is_edit)

end
 
 def view_carton_pack_product(carton_pack_product,caption = nil)
   
    action = "view_paging_handler" if !caption
    field_configs = Array.new
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'carton_pack_product_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (carton_pack_type_id) on related table: carton_pack_types
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'type_code'}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (basic_pack_id) on related table: basic_packs
#	----------------------------------------------------------------------------------------------
	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'basic_pack_code'}
 
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (carton_pack_style_id) on related table: carton_pack_styles
#	-----------------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'carton_pack_style_code'}

 
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'height'}
						
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'nett_mass'}

	build_form(carton_pack_product,field_configs,action,'carton_pack_product',"back")
  
 
 
 end
 
 
 def build_carton_pack_product_search_form(carton_pack_product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:carton_pack_product_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["carton_pack_product_type_code","carton_pack_product_basic_pack_code","carton_pack_product_carton_pack_style_code","carton_pack_product_height"])
	#Observers for search combos
	type_code_observer  = {:updated_field_id => "basic_pack_code_cell",
					 :remote_method => 'carton_pack_product_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["carton_pack_product_type_code"]}

	session[:carton_pack_product_search_form][:type_code_observer] = type_code_observer

	basic_pack_code_observer  = {:updated_field_id => "carton_pack_style_code_cell",
					 :remote_method => 'carton_pack_product_basic_pack_code_search_combo_changed',
					 :on_completed_js => search_combos_js["carton_pack_product_basic_pack_code"]}

	session[:carton_pack_product_search_form][:basic_pack_code_observer] = basic_pack_code_observer

	carton_pack_style_code_observer  = {:updated_field_id => "height_cell",
					 :remote_method => 'carton_pack_product_carton_pack_style_code_search_combo_changed',
					 :on_completed_js => search_combos_js["carton_pack_product_carton_pack_style_code"]}

	session[:carton_pack_product_search_form][:carton_pack_style_code_observer] = carton_pack_style_code_observer

 
	type_codes = CartonPackProduct.find_by_sql('select distinct type_code from carton_pack_products').map{|g|[g.type_code]}
	type_codes.unshift("<empty>")
	if is_flat_search
		basic_pack_codes = CartonPackProduct.find_by_sql('select distinct basic_pack_code from carton_pack_products').map{|g|[g.basic_pack_code]}
		basic_pack_codes.unshift("<empty>")
		carton_pack_style_codes = CartonPackProduct.find_by_sql('select distinct carton_pack_style_code from carton_pack_products').map{|g|[g.carton_pack_style_code]}
		carton_pack_style_codes.unshift("<empty>")
		sizes = CartonPackProduct.find_by_sql('select distinct height from carton_pack_products').map{|g|[g.height]}
		sizes.unshift("<empty>")
		type_code_observer = nil
		basic_pack_code_observer = nil
		carton_pack_style_code_observer = nil
	else
		 basic_pack_codes = ["Select a value from type_code"]
		 carton_pack_style_codes = ["Select a value from basic_pack_code"]
		 sizes = ["Select a value from carton_pack_style_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'type_code',
						:settings => {:list => type_codes},
						:observer => type_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'basic_pack_code',
						:settings => {:list => basic_pack_codes},
						:observer => basic_pack_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'carton_pack_style_code',
						:settings => {:list => carton_pack_style_codes},
						:observer => carton_pack_style_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'height',
						:settings => {:list => sizes}}
 
	build_form(carton_pack_product,field_configs,action,'carton_pack_product',caption,false)

 end



 def build_carton_pack_product_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'carton_pack_product_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'type_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'basic_pack_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'carton_pack_style_code'}
	column_configs[4] = {:field_type => 'text',:field_name => 'height'}
	column_configs[5] = {:field_type => 'text',:field_name => 'nett_mass'}
#	----------------------
#	define action columns
#	----------------------
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view carton_pack_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_carton_pack_product',
				:id_column => 'id'}}
	   
	   if @can_edit
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view carton_pack_product',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_carton_pack_product',
				:id_column => 'id'}}
				
	   end		
 return get_data_grid(data_set,column_configs)
end

end
