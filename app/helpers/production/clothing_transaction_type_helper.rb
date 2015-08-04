module Production::ClothingTransactionTypeHelper
 
 
 def build_clothing_transaction_type_form(clothing_transaction_type,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:clothing_transaction_type_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = []
	field_configs << {:field_type => 'TextField',
						:field_name => 'clothing_transaction_type_code'}

	build_form(clothing_transaction_type,field_configs,action,'clothing_transaction_type',caption,is_edit)

end
 
 
 def build_clothing_transaction_type_search_form(clothing_transaction_type,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:clothing_transaction_type_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["clothing_transaction_type_clothing_transaction_type_code"])
	#Observers for search combos
 
	clothing_transaction_type_codes = ClothingTransactionType.find_by_sql('select distinct clothing_transaction_type_code from clothing_transaction_types').map{|g|[g.clothing_transaction_type_code]}
	clothing_transaction_type_codes.unshift("<empty>")
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
						:field_name => 'clothing_transaction_type_code',
						:settings => {:list => clothing_transaction_type_codes}}
 
	build_form(clothing_transaction_type,field_configs,action,'clothing_transaction_type',caption,false)

end



 def build_clothing_transaction_type_grid(data_set,can_edit,can_delete)

	column_configs = []
	column_configs << {:field_type => 'text',:field_name => 'clothing_transaction_type_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs << {:field_type => 'action',:field_name => 'edit clothing_transaction_type',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_clothing_transaction_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete clothing_transaction_type',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_clothing_transaction_type',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
