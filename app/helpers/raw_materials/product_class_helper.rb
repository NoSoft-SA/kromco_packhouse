module RawMaterials::ProductClassHelper
 
 
 def build_product_class_form(product_class,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:product_class_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'product_class_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'product_class_description'}

	build_form(product_class,field_configs,action,'product_class',caption,is_edit)

end
 
 
 def build_product_class_search_form(product_class,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:product_class_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["product_class_product_class_code"])
	#Observers for search combos
 
	product_class_codes = ProductClass.find_by_sql('select distinct product_class_code from product_classes').map{|g|[g.product_class_code]}
	product_class_codes.unshift("<empty>")
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
						:field_name => 'product_class_code',
						:settings => {:list => product_class_codes}}
 
	build_form(product_class,field_configs,action,'product_class',caption,false)

end



 def build_product_class_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'product_class_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'product_class_description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit product_class',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_product_class',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete product_class',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_product_class',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
