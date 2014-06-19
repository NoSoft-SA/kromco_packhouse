module Products::PalletFormatProductHelper
 
 
 def build_pallet_format_product_form(pallet_format_product,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:pallet_format_product_form]= Hash.new
	pallet_base_codes = PalletBase.find_by_sql('select distinct pallet_base_code from pallet_bases').map{|g|[g.pallet_base_code]}
	pallet_base_codes.unshift("<empty>")
	market_codes = PalletFormatMarket.find_by_sql('select distinct market_code from pallet_format_markets').map{|g|[g.market_code]}
	market_codes.unshift("<empty>")
	stack_type_codes = StackType.find_by_sql('select distinct stack_type_code from stack_types').map{|g|[g.stack_type_code]}
	stack_type_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'pallet_format_product_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pallet_format_market_id) on related table: pallet_format_markets
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'market_code',
						:settings => {:list => market_codes}}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'stack_type_code',
						:settings => {:list => stack_type_codes}}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pallet_base_id) on related table: pallet_bases
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'pallet_base_code',
						:settings => {:list => pallet_base_codes}}
 
	build_form(pallet_format_product,field_configs,action,'pallet_format_product',caption,is_edit)

end
 
 
 def view_pallet_format_product(pallet_format_product,action = nil)
 
  action = "view_paging_handler" if !action
  field_configs = Array.new
  field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'pallet_format_product_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pallet_format_market_id) on related table: pallet_format_markets
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'market_code'}
 
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'stack_type_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pallet_base_id) on related table: pallet_bases
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'pallet_base_code'}
 
	build_form(pallet_format_product,field_configs,action,'pallet_format_product',"back")
 
 end
 
 def build_pallet_format_product_search_form(pallet_format_product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:pallet_format_product_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["pallet_format_product_market_code","pallet_format_product_stack_type_code","pallet_format_product_pallet_base_code"])
	#Observers for search combos
	market_code_observer  = {:updated_field_id => "stack_type_code_cell",
					 :remote_method => 'pallet_format_product_market_code_search_combo_changed',
					 :on_completed_js => search_combos_js["pallet_format_product_market_code"]}

	session[:pallet_format_product_search_form][:market_code_observer] = market_code_observer

	stack_type_code_observer  = {:updated_field_id => "pallet_base_code_cell",
					 :remote_method => 'pallet_format_product_stack_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["pallet_format_product_stack_type_code"]}

	session[:pallet_format_product_search_form][:stack_type_code_observer] = stack_type_code_observer

 
	market_codes = PalletFormatProduct.find_by_sql('select distinct market_code from pallet_format_products').map{|g|[g.market_code]}
	market_codes.unshift("<empty>")
	if is_flat_search
		stack_type_codes = StackType.find_by_sql('select distinct stack_type_code from stack_types').map{|g|[g.stack_type_code]}
		stack_type_codes.unshift("<empty>")
		pallet_base_codes = PalletFormatProduct.find_by_sql('select distinct pallet_base_code from pallet_format_products').map{|g|[g.pallet_base_code]}
		pallet_base_codes.unshift("<empty>")
		market_code_observer = nil
		stack_type_code_observer = nil
	else
		 stack_type_codes = ["Select a value from market_code"]
		 pallet_base_codes = ["Select a value from stack_type_code "]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'market_code',
						:settings => {:list => market_codes},
						:observer => market_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'stack_type_code',
						:settings => {:list => stack_type_codes},
						:observer => stack_type_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'pallet_base_code',
						:settings => {:list => pallet_base_codes}}
 
	build_form(pallet_format_product,field_configs,action,'pallet_format_product',caption,false)

end



 def build_pallet_format_product_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'pallet_format_product_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'market_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'stack_type_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'pallet_base_code'}
#	----------------------
#	define action columns
#	----------------------
	
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view pallet_format_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_pallet_format_product',
				:id_column => 'id'}}
	


 return get_data_grid(data_set,column_configs)
end

end
