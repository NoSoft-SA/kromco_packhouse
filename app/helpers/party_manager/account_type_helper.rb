module PartyManager::AccountTypeHelper
 
 
 def build_account_type_form(account_type,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:account_type_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'account_type_name'}

	build_form(account_type,field_configs,action,'account_type',caption,is_edit)

end
 
 
 def build_account_type_search_form(account_type,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:account_type_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["account_type_account_type_name"])
	#Observers for search combos
 
	account_type_names = AccountType.find_by_sql('select distinct account_type_name from account_types').map{|g|[g.account_type_name]}
	account_type_names.unshift("<empty>")
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
						:field_name => 'account_type_name',
						:settings => {:list => account_type_names}}
 
	build_form(account_type,field_configs,action,'account_type',caption,false)

end



 def build_account_type_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'account_type_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit account_type',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_account_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete account_type',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_account_type',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
