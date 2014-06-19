module Products::ItemPackProductHelper
 
 
 def build_item_pack_product_form(item_pack_product,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:item_pack_product_form]= Hash.new
	grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map{|g|[g.grade_code]}
	grade_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: marketing_varieties
	combos_js_for_marketing_varieties = gen_combos_clear_js_for_combos(["item_pack_product_commodity_group_code","item_pack_product_commodity_code","item_pack_product_marketing_variety_code"])
	combos_js_for_standard_size_counts = gen_combos_clear_js_for_combos(["item_pack_product_commodity_code","item_pack_product_basic_pack","item_pack_product_actual_count"])
	#Observers for combos representing the key fields of fkey table: marketing_variety_id
	product_class_codes = ProductClass.find_by_sql('select distinct product_class_code from product_classes').map{|g|[g.product_class_code]}
	product_class_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: standard_size_counts
	combos_js_for_marketing_varieties = gen_combos_clear_js_for_combos(["item_pack_product_commodity_group_code","item_pack_product_commodity_code","item_pack_product_basic_pack"])
	combos_js_for_standard_size_counts = gen_combos_clear_js_for_combos(["item_pack_product_commodity_code","item_pack_product_basic_pack","item_pack_product_standard_size_count_value"])
	#Observers for combos representing the key fields of fkey table: standard_size_count_id
	cosmetic_codes = CosmeticCode.find_by_sql('select distinct cosmetic_code from cosmetic_codes').map{|g|[g.cosmetic_code]}
	cosmetic_codes.unshift("<empty>")
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'item_pack_product_commodity_group_code_changed',
					 :on_completed_js => combos_js_for_marketing_varieties ["item_pack_product_commodity_group_code"]}

	session[:item_pack_product_form][:commodity_group_code_observer] = commodity_group_code_observer

#	commodity_code_observer  = {:updated_field_id => "basic_pack_cell",
#					 :remote_method => 'item_pack_product_commodity_code_changed',
#					 :on_completed_js => combos_js_for_marketing_varieties ["item_pack_product_commodity_code"]}

	#session[:item_pack_product_form][:commodity_code_observer] = commodity_code_observer

#	combo lists for table: marketing_varieties

	commodity_group_codes = nil 
	commodity_codes = nil 
	marketing_variety_codes = nil 
	
	treatment_codes = Treatment.find_by_sql("select distinct treatment_code from treatments where treatment_type_code = 'PACKHOUSE'").map{|g|[g.treatment_code]}
	treatment_codes.unshift("<empty>")
 
	commodity_group_codes = ItemPackProduct.get_all_commodity_group_codes
	if item_pack_product == nil||is_create_retry
		 commodity_codes = ["Select a value from commodity_group_code"]
		 marketing_variety_codes = ["Select a value from commodity_code"]
	else
		commodity_codes = ItemPackProduct.commodity_codes_for_commodity_group_code(item_pack_product.marketing_variety.commodity_group_code)
		marketing_variety_codes = ItemPackProduct.marketing_variety_codes_for_commodity_code_and_commodity_group_code(item_pack_product.marketing_variety.commodity_code, item_pack_product.marketing_variety.commodity_group_code)
	end
	commodity_code_observer  = {:updated_field_id => "basic_pack_code_cell",
					 :remote_method => 'item_pack_product_commodity_code_changed',
					 :on_completed_js => combos_js_for_standard_size_counts ["item_pack_product_commodity_code"]}
#
 	session[:item_pack_product_form][:commodity_code_observer] = commodity_code_observer

	basic_pack_observer  = {:updated_field_id => "standard_size_count_value_cell",
					 :remote_method => 'item_pack_product_basic_pack_changed',
					 :on_completed_js => combos_js_for_standard_size_counts ["item_pack_product_basic_pack"]}

	session[:item_pack_product_form][:basic_pack_observer] = basic_pack_observer

#	combo lists for table: standard_size_counts

	commodity_codes = nil 
	basic_packs = nil 
	std_counts = nil 
 
	commodity_codes = ["Select a value from commodity group code"]#"ItemPackProduct.get_all_commodity_codes
	commodity_codes.unshift "<empty>"
	if item_pack_product == nil||is_create_retry
		 basic_packs = ["Select a value from commodity_code"]
		 std_counts = ["Select a value from basic_pack"]
	else
		basic_packs = ItemPackProduct.basic_packs_for_commodity_code(item_pack_product.standard_size_count.commodity_code)
		std_counts = ItemPackProduct.std_counts_for_basic_pack_and_commodity_code(item_pack_product.standard_size_count.basic_pack_code, item_pack_product.standard_size_count.commodity_code)
	end

   
   
   
   if !item_pack_product
     size_refs = []
    @item_pack_product = ItemPackProduct.new
   # @item_pack_product.size_ref = "<empty>"
   else
     size_refs = SizeRef.find_all_by_commodity_code(!item_pack_product.commodity_code).map{|g|[g.size_ref_code]}
   end

   size_refs.unshift("<empty>")

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'item_pack_product_code'}

	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_code',
						:settings => {:list => treatment_codes}}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (cosmetic_code_id) on related table: cosmetic_codes
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'cosmetic_code_name',
						:settings => {:list => cosmetic_codes}}
 
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (grade_id) on related table: grades
#	-----------------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grade_codes}}


 
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (product_class_id) on related table: product_classes
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'product_class_code',
						:settings => {:list => product_class_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (marketing_variety_id) on related table: marketing_varieties
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'marketing_variety_code',
						:settings => {:list => marketing_variety_codes}}
	
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'basic_pack_code',
						:settings => {:list => basic_packs},
						:observer => basic_pack_observer}
 
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_value',
						:settings => {:list => std_counts}}

   field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_value',
						:settings => {:list => std_counts}}

   field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'size_ref',
						:settings => {:list => size_refs}}

   field_configs[field_configs.length] =  {:field_type => 'TextField',
						:field_name => 'price_per_kg'}
 
	build_form(item_pack_product,field_configs,action,'item_pack_product',caption,is_edit)

end
 
 
 def build_item_pack_product_search_form(item_pack_product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:item_pack_product_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["item_pack_product_commodity_code","item_pack_product_marketing_variety_code","item_pack_product_actual_count","item_pack_product_product_class_code","item_pack_product_grade_code","item_pack_product_cosmetic_code"])
	#Observers for search combos
	commodity_code_observer  = {:updated_field_id => "marketing_variety_code_cell",
					 :remote_method => 'item_pack_product_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["item_pack_product_commodity_code"]}

	session[:item_pack_product_search_form][:commodity_code_observer] = commodity_code_observer

	marketing_variety_code_observer  = {:updated_field_id => "actual_count_cell",
					 :remote_method => 'item_pack_product_marketing_variety_code_search_combo_changed',
					 :on_completed_js => search_combos_js["item_pack_product_marketing_variety_code"]}

	session[:item_pack_product_search_form][:marketing_variety_code_observer] = marketing_variety_code_observer

	actual_count_observer  = {:updated_field_id => "product_class_code_cell",
					 :remote_method => 'item_pack_product_actual_count_search_combo_changed',
					 :on_completed_js => search_combos_js["item_pack_product_actual_count"]}

	session[:item_pack_product_search_form][:actual_count_observer] = actual_count_observer

	product_class_code_observer  = {:updated_field_id => "grade_code_cell",
					 :remote_method => 'item_pack_product_product_class_code_search_combo_changed',
					 :on_completed_js => search_combos_js["item_pack_product_product_class_code"]}

	session[:item_pack_product_search_form][:product_class_code_observer] = product_class_code_observer

	grade_code_observer  = {:updated_field_id => "cosmetic_code_cell",
					 :remote_method => 'item_pack_product_grade_code_search_combo_changed',
					 :on_completed_js => search_combos_js["item_pack_product_grade_code"]}

	session[:item_pack_product_search_form][:grade_code_observer] = grade_code_observer

 
	commodity_codes = ItemPackProduct.find_by_sql('select distinct commodity_code from item_pack_products').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
	if is_flat_search
		marketing_variety_codes = ItemPackProduct.find_by_sql('select distinct marketing_variety_code from item_pack_products').map{|g|[g.marketing_variety_code]}
		marketing_variety_codes.unshift("<empty>")
		actual_counts = ItemPackProduct.find_by_sql('select distinct actual_count from item_pack_products').map{|g|[g.actual_count]}
		actual_counts.unshift("<empty>")
		product_class_codes = ItemPackProduct.find_by_sql('select distinct product_class_code from item_pack_products').map{|g|[g.product_class_code]}
		product_class_codes.unshift("<empty>")
		grade_codes = ItemPackProduct.find_by_sql('select distinct grade_code from item_pack_products').map{|g|[g.grade_code]}
		grade_codes.unshift("<empty>")
		basic_pack_codes = ItemPackProduct.find_by_sql('select distinct basic_pack_code from item_pack_products').map{|g|[g.basic_pack_code]}
		grade_codes.unshift("<empty>")
		cosmetic_codes = ItemPackProduct.find_by_sql('select distinct cosmetic_code_name from item_pack_products').map{|g|[g.cosmetic_code_name]}
		cosmetic_codes.unshift("<empty>")
		commodity_code_observer = nil
		marketing_variety_code_observer = nil
		actual_count_observer = nil
		product_class_code_observer = nil
		grade_code_observer = nil
	else
		 marketing_variety_codes = ["Select a value from commodity_code"]
		 actual_counts = ["Select a value from marketing_variety_code"]
		 product_class_codes = ["Select a value from actual_count"]
		 grade_codes = ["Select a value from product_class_code"]
		 cosmetic_codes = ["Select a value from grade_code"]
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
						:field_name => 'marketing_variety_code',
						:settings => {:list => marketing_variety_codes},
						:observer => marketing_variety_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'actual_count',
						:settings => {:list => actual_counts},
						:observer => actual_count_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'product_class_code',
						:settings => {:list => product_class_codes},
						:observer => product_class_code_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grade_codes},
						:observer => grade_code_observer}
 
	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'cosmetic_code_name',
						:settings => {:list => cosmetic_codes}}
						
	if(is_flat_search)
	  field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'basic_pack_code',
						:settings => {:list => basic_pack_codes}}
	end
 
	build_form(item_pack_product,field_configs,action,'item_pack_product',caption,false)

end

def view_item_pack_product(item_pack_product,action)

  field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'item_pack_product_code'}
						
	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'commodity_code'}
				
 
	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'marketing_variety_code'}
					
 
	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'actual_count'}
						
	field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'standard_size_count_value'}
 
	field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'product_class_code'}
 
	field_configs[6] =  {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'cosmetic_code_name'}
						
	field_configs[8] =  {:field_type => 'LabelField',
						:field_name => 'treatment_code'}
 
	build_form(item_pack_product,field_configs,action,'item_pack_product',"back")
  


end


 def build_item_pack_product_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'item_pack_product_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'product_class_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'cosmetic_code_name'}
	column_configs[4] = {:field_type => 'text',:field_name => 'grade_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'marketing_variety_code'}
	column_configs[6] = {:field_type => 'text',:field_name => 'treatment_code'}
	column_configs[7] = {:field_type => 'text',:field_name => 'commodity_group_code'}
	column_configs[8] = {:field_type => 'text',:field_name => 'actual_count'}
	column_configs[9] = {:field_type => 'text',:field_name => 'basic_pack_code'}
	column_configs[10] = {:field_type => 'text',:field_name => 'standard_size_count_value'}
  column_configs[11] = {:field_type => 'text',:field_name => 'size_ref'}
	
#	----------------------
#	define action columns
#	----------------------
	
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit item_pack_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_item_pack_product',
				:id_column => 'id'}}
	
	
 return get_data_grid(data_set,column_configs)
end

end
