module Products::CartonsPerPalletHelper
 
 
 def build_cartons_per_pallet_form(cartons_per_pallet,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:cartons_per_pallet_form]= Hash.new
	pallet_format_product_codes = PalletFormatProduct.find_by_sql('select distinct pallet_format_product_code from pallet_format_products').map{|g|[g.pallet_format_product_code]}
	pallet_format_product_codes.unshift("<empty>")
	carton_pack_product_codes = CartonPackProduct.find_by_sql('select distinct carton_pack_product_code from carton_pack_products').map{|g|[g.carton_pack_product_code]}
	carton_pack_product_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pallet_format_product_id) on related table: pallet_format_products
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'pallet_format_product_code',
						:settings => {:list => pallet_format_product_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (carton_pack_product_id) on related table: carton_pack_products
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'carton_pack_product_code',
						:settings => {:list => carton_pack_product_codes}}
 
	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'description'}

	field_configs[3] = {:field_type => 'TextField',
						:field_name => 'cartons_per_pallet'}

	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'layers_per_pallet'}

	field_configs[5] = {:field_type => 'TextField',
						:field_name => 'cartons_per_layer'}

	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'cpp_code'}

	build_form(cartons_per_pallet,field_configs,action,'cartons_per_pallet',caption,is_edit)

end
 
 
 def build_cartons_per_pallet_search_form(cartons_per_pallet,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:cartons_per_pallet_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["cartons_per_pallet_pallet_format_product_code","cartons_per_pallet_carton_pack_product_code","cartons_per_pallet_cartons_per_pallet","cartons_per_pallet_layers_per_pallet"])
	#Observers for search combos
	pallet_format_product_code_observer  = {:updated_field_id => "carton_pack_product_code_cell",
					 :remote_method => 'cartons_per_pallet_pallet_format_product_code_search_combo_changed',
					 :on_completed_js => search_combos_js["cartons_per_pallet_pallet_format_product_code"]}

	session[:cartons_per_pallet_search_form][:pallet_format_product_code_observer] = pallet_format_product_code_observer

	carton_pack_product_code_observer  = {:updated_field_id => "cartons_per_pallet_cell",
					 :remote_method => 'cartons_per_pallet_carton_pack_product_code_search_combo_changed',
					 :on_completed_js => search_combos_js["cartons_per_pallet_carton_pack_product_code"]}

	session[:cartons_per_pallet_search_form][:carton_pack_product_code_observer] = carton_pack_product_code_observer

	cartons_per_pallet_observer  = {:updated_field_id => "layers_per_pallet_cell",
					 :remote_method => 'cartons_per_pallet_cartons_per_pallet_search_combo_changed',
					 :on_completed_js => search_combos_js["cartons_per_pallet_cartons_per_pallet"]}

	session[:cartons_per_pallet_search_form][:cartons_per_pallet_observer] = cartons_per_pallet_observer

 
	pallet_format_product_codes = CartonsPerPallet.find_by_sql('select distinct pallet_format_product_code from cartons_per_pallets').map{|g|[g.pallet_format_product_code]}
	pallet_format_product_codes.unshift("<empty>")
	if is_flat_search
		carton_pack_product_codes = CartonsPerPallet.find_by_sql('select distinct carton_pack_product_code from cartons_per_pallets').map{|g|[g.carton_pack_product_code]}
		carton_pack_product_codes.unshift("<empty>")
		cartons_per_pallets = CartonsPerPallet.find_by_sql('select distinct cartons_per_pallet from cartons_per_pallets').map{|g|[g.cartons_per_pallet]}
		cartons_per_pallets.unshift("<empty>")
		layers_per_pallets = CartonsPerPallet.find_by_sql('select distinct layers_per_pallet from cartons_per_pallets').map{|g|[g.layers_per_pallet]}
		layers_per_pallets.unshift("<empty>")
		pallet_format_product_code_observer = nil
		carton_pack_product_code_observer = nil
		cartons_per_pallet_observer = nil
	else
		 carton_pack_product_codes = ["Select a value from pallet_format_product_code"]
		 cartons_per_pallets = ["Select a value from carton_pack_product_code"]
		 layers_per_pallets = ["Select a value from cartons_per_pallet"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'pallet_format_product_code',
						:settings => {:list => pallet_format_product_codes},
						:observer => pallet_format_product_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'carton_pack_product_code',
						:settings => {:list => carton_pack_product_codes},
						:observer => carton_pack_product_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'cartons_per_pallet',
						:settings => {:list => cartons_per_pallets},
						:observer => cartons_per_pallet_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'layers_per_pallet',
						:settings => {:list => layers_per_pallets}}
 
	build_form(cartons_per_pallet,field_configs,action,'cartons_per_pallet',caption,false)

end



 def build_cartons_per_pallet_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'pallet_format_product_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'carton_pack_product_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'description'}
	column_configs[3] = {:field_type => 'text',:field_name => 'cartons_per_pallet'}
	column_configs[4] = {:field_type => 'text',:field_name => 'layers_per_pallet'}
	column_configs[5] = {:field_type => 'text',:field_name => 'cartons_per_layer'}
	column_configs[6] = {:field_type => 'text',:field_name => 'cpp_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit cartons_per_pallet',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_cartons_per_pallet',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete cartons_per_pallet',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_cartons_per_pallet',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
