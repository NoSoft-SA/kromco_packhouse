module Products::HandlingProductHelper
 
 
 def build_handling_product_form(handling_product,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:handling_product_form]= Hash.new
	handling_product_type_codes = HandlingProductType.find_by_sql('select distinct handling_product_type_code from handling_product_types').map{|g|[g.handling_product_type_code]}
	handling_product_type_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'handling_product_code'}

#	field_configs[1] = {:field_type => 'TextField',
#						:field_name => 'standard_size_count_code'}

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (handling_product_type_id) on related table: handling_product_types
#	-----------------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'handling_product_type_code',
						:settings => {:list => handling_product_type_codes}}

 
	build_form(handling_product,field_configs,action,'handling_product',caption,is_edit)

end
 
 
 def build_handling_product_search_form(handling_product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:handling_product_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["handling_product_handling_product_code","handling_product_standard_size_count_code"])
	#Observers for search combos
	handling_product_code_observer  = {:updated_field_id => "standard_size_count_code_cell",
					 :remote_method => 'handling_product_handling_product_code_search_combo_changed',
					 :on_completed_js => search_combos_js["handling_product_handling_product_code"]}

	session[:handling_product_search_form][:handling_product_code_observer] = handling_product_code_observer

 
	handling_product_codes = HandlingProduct.find_by_sql('select distinct handling_product_code from handling_products').map{|g|[g.handling_product_code]}
	handling_product_codes.unshift("<empty>")
	if is_flat_search
		standard_size_count_codes = HandlingProduct.find_by_sql('select distinct standard_size_count_code from handling_products').map{|g|[g.standard_size_count_code]}
		standard_size_count_codes.unshift("<empty>")
		handling_product_code_observer = nil
	else
		 standard_size_count_codes = ["Select a value from handling_product_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'handling_product_code',
						:settings => {:list => handling_product_codes},
						:observer => handling_product_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_code',
						:settings => {:list => standard_size_count_codes}}
 
	build_form(handling_product,field_configs,action,'handling_product',caption,false)

end



 def build_handling_product_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'handling_product_code'}
	#column_configs[1] = {:field_type => 'text',:field_name => 'standard_size_count_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'handling_product_type_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
#		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit handling_product',
#			:settings => 
#				 {:link_text => 'edit',
#				:target_action => 'edit_handling_product',
#				:id_column => 'id'}}
	end

	if can_delete
#		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete handling_product',
#			:settings => 
#				 {:link_text => 'delete',
#				:target_action => 'delete_handling_product',
#				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
