module Production::ClothingItemHelper
 
 
 def build_clothing_item_form(clothing_item,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:clothing_item_form]= Hash.new
	clothing_transaction_type_codes = ClothingTransactionType.find_by_sql('select distinct clothing_transaction_type_code from clothing_transaction_types').map{|g|[g.clothing_transaction_type_code]}
	clothing_transaction_type_codes.unshift("<empty>")
	clock_codes = ClothablePerson.find_by_sql('select distinct clock_code from clothable_people').map{|g|[g.clock_code]}
	clock_codes.unshift("<empty>")
	clothing_type_codes = ClothingType.find_by_sql('select distinct clothing_type_code from clothing_types').map{|g|[g.clothing_type_code]}
	clothing_type_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = []
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (clothable_person_id) on related table: clothable_people
#	----------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'clock_code',
						:settings => {:list => clock_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (clothing_type_id) on related table: clothing_types
#	----------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'clothing_type_code',
						:settings => {:list => clothing_type_codes}}
 
	field_configs << {:field_type => 'DateTimeField',
						:field_name => 'created_on'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (clothing_transaction_type_id) on related table: clothing_transaction_types
#	----------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'clothing_transaction_type_code',
						:settings => {:list => clothing_transaction_type_codes}}
 
	field_configs << {:field_type => 'TextField',
						:field_name => 'clothing_transaction_quantity'}

	build_form(clothing_item,field_configs,action,'clothing_item',caption,is_edit)

end
 
 
 def build_clothing_item_search_form(clothing_item,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:clothing_item_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["clothing_item_clothing_transaction_type_id"])
	#Observers for search combos
 
	clothing_transaction_type_ids = ClothingItem.find_by_sql('select distinct clothing_transaction_type_id from clothing_items').map{|g|[g.clothing_transaction_type_id]}
	clothing_transaction_type_ids.unshift("<empty>")
	if is_flat_search
	else
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = []
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'clothing_transaction_type_id',
						:settings => {:list => clothing_transaction_type_ids}}
 
	build_form(clothing_item,field_configs,action,'clothing_item',caption,false)

end



 def build_clothing_item_grid(data_set,can_edit,can_delete)

	column_configs = []
	column_configs << {:field_type => 'text',:field_name => 'clothing_type_code'}
	column_configs << {:field_type => 'text',:field_name => 'clock_code'}
	column_configs << {:field_type => 'text',:field_name => 'created_on'}
	column_configs << {:field_type => 'text',:field_name => 'clothing_transaction_type_code'}
	column_configs << {:field_type => 'text',:field_name => 'clothing_transaction_quantity'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs << {:field_type => 'action',:field_name => 'edit clothing_item',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_clothing_item',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete clothing_item',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_clothing_item',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
