module Products::UnitPackProductHelper
 
 
 def build_unit_pack_product_form(unit_pack_product,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:unit_pack_product_form]= Hash.new
	type_codes = UnitPackProductType.find_by_sql('select distinct type_code from unit_pack_product_types').map{|g|[g.type_code]}
	type_codes.unshift("<empty>")
	subtype_codes = UnitPackProductSubtype.find_by_sql('select distinct subtype_code from unit_pack_product_subtypes').map{|g|[g.subtype_code]}
	subtype_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	field_configs = Array.new
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'unit_pack_product_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'product_description'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (unit_pack_product_type_id) on related table: unit_pack_product_types
#	----------------------------------------------------------------------------------------------
	if !is_edit
	   field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'type_code',
						:settings => {:list => type_codes}}

  
   #	----------------------------------------------------------------------------------------------
   #	Combo fields to represent foreign key (unit_pack_product_subtype_id) on related table: unit_pack_product_subtypes
   #	----------------------------------------------------------------------------------------------
	
	   field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'subtype_code',
						:settings => {:list => subtype_codes}}
	
	
 
	   field_configs[4] = {:field_type => 'TextField',
						:field_name => 'fruit_per_ru'}
						
	    field_configs[5] = {:field_type => 'TextField',
						:field_name => 'nett_mass'}

      field_configs[6] = {:field_type => 'TextField',
						:field_name => 'external_fruit_per_ru'}

	else
	 
	 field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'type_code'}
	
	 field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'subtype_code'}
						
	 field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'fruit_per_ru'}
						
	 field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'nett_mass'}

  field_configs[6] = {:field_type => 'TextField',
						:field_name => 'external_fruit_per_ru'}

						
	end
	
	 field_configs[7] = {:field_type => 'TextField',
						:field_name => 'gross_mass'}					
						

	build_form(unit_pack_product,field_configs,action,'unit_pack_product',caption,is_edit)

end
 
def build_unit_pack_product_search_form(unit_pack_product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:unit_pack_product_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["unit_pack_product_type_code","unit_pack_product_subtype_code","unit_pack_product_gross_mass","unit_pack_product_fruit_per_ru"])
	#Observers for search combos
	type_code_observer  = {:updated_field_id => "subtype_code_cell",
					 :remote_method => 'unit_pack_product_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["unit_pack_product_type_code"]}

	session[:unit_pack_product_search_form][:type_code_observer] = type_code_observer

	subtype_code_observer  = {:updated_field_id => "gross_mass_cell",
					 :remote_method => 'unit_pack_product_subtype_code_search_combo_changed',
					 :on_completed_js => search_combos_js["unit_pack_product_subtype_code"]}

	session[:unit_pack_product_search_form][:subtype_code_observer] = subtype_code_observer

	gross_mass_observer  = {:updated_field_id => "fruit_per_ru_cell",
					 :remote_method => 'unit_pack_product_gross_mass_search_combo_changed',
					 :on_completed_js => search_combos_js["unit_pack_product_gross_mass"]}

	session[:unit_pack_product_search_form][:gross_mass_observer] = gross_mass_observer

 
	type_codes = UnitPackProduct.find_by_sql('select distinct type_code from unit_pack_products').map{|g|[g.type_code]}
	type_codes.unshift("<empty>")
	if is_flat_search
		subtype_codes = UnitPackProduct.find_by_sql('select distinct subtype_code from unit_pack_products').map{|g|[g.subtype_code]}
		subtype_codes.unshift("<empty>")
		gross_masses = UnitPackProduct.find_by_sql('select distinct gross_mass from unit_pack_products').map{|g|[g.gross_mass]}
		gross_masses.unshift("<empty>")
		fruit_per_rus = UnitPackProduct.find_by_sql('select distinct fruit_per_ru from unit_pack_products').map{|g|[g.fruit_per_ru]}
		fruit_per_rus.unshift("<empty>")
		type_code_observer = nil
		subtype_code_observer = nil
		gross_mass_observer = nil
	else
		 subtype_codes = ["Select a value from type_code"]
		 gross_masses = ["Select a value from subtype_code"]
		 fruit_per_rus = ["Select a value from gross_mass"]
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
						:field_name => 'subtype_code',
						:settings => {:list => subtype_codes},
						:observer => subtype_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'gross_mass',
						:settings => {:list => gross_masses},
						:observer => gross_mass_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'fruit_per_ru',
						:settings => {:list => fruit_per_rus}}

   field_configs[4] =  {:field_type => 'TextField',
						:field_name => 'external_fruit_per_ru'}
 
	build_form(unit_pack_product,field_configs,action,'unit_pack_product',caption,false)

end



def view_unit_pack_product(unit_pack_product,action = nil)

    action = "view_paging_handler" if !action
    field_configs = Array.new
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'unit_pack_product_code'}

	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'product_description'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (unit_pack_product_type_id) on related table: unit_pack_product_types
#	----------------------------------------------------------------------------------------------
	
	   field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'type_code'}
	
	
 
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'gross_mass'}
  
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (unit_pack_product_subtype_id) on related table: unit_pack_product_subtypes
#	----------------------------------------------------------------------------------------------
	
	   field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'subtype_code'}
	
	
 
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'fruit_per_ru'}
						
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'nett_mass'}

  field_configs[7] = {:field_type => 'LabelField',
						:field_name => 'external_fruit_per_ru'}
						

	build_form(unit_pack_product,field_configs,action,'unit_pack_product',"back")



end


 def build_unit_pack_product_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'unit_pack_product_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'product_description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'type_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'gross_mass'}
	column_configs[4] = {:field_type => 'text',:field_name => 'subtype_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'fruit_per_ru'}
	column_configs[6] = {:field_type => 'text',:field_name => 'nett_mass'}
  column_configs[7] = {:field_type => 'text',:field_name => 'external_fruit_per_ru'}
	
	
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view unit_pack_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_unit_pack_product',
				:id_column => 'id'}}
	
       if @can_edit 
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit unit_pack_product',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_unit_pack_product',
				:id_column => 'id'}}
	   end
	
 return get_data_grid(data_set,column_configs)
 
end

end
