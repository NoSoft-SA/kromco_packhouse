module PartyManager::AccountHelper
 
 #==========================
 #ACCOUNTS PARTY ROLES CODE
 #==========================
 def build_accounts_parties_role_form(accounts_parties_role,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:accounts_parties_role_form]= Hash.new
	account_codes = Account.find_by_sql('select distinct account_code from accounts').map{|g|[g.account_code]}
	account_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: parties_roles
	combos_js_for_parties_roles = gen_combos_clear_js_for_combos(["accounts_parties_role_party_type_name","accounts_parties_role_party_name","accounts_parties_role_role_name"])
	#Observers for combos representing the key fields of fkey table: parties_role_id
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'accounts_parties_role_party_type_name_changed',
					 :on_completed_js => combos_js_for_parties_roles ["accounts_parties_role_party_type_name"]}

	session[:accounts_parties_role_form][:party_type_name_observer] = party_type_name_observer

	party_name_observer  = {:updated_field_id => "role_name_cell",
					 :remote_method => 'accounts_parties_role_party_name_changed',
					 :on_completed_js => combos_js_for_parties_roles ["accounts_parties_role_party_name"]}

	session[:accounts_parties_role_form][:party_name_observer] = party_name_observer

#	combo lists for table: parties_roles

	party_type_names = nil 
	party_names = nil 
	role_names = nil 
 
	party_type_names = AccountsPartiesRole.get_all_party_type_names
	party_type_names.unshift("<empty>")
	if accounts_parties_role == nil||is_create_retry
		 party_names = ["Select a value from party_type_name"]
		 role_names = ["Select a value from party_name"]
	else
		party_names = AccountsPartiesRole.party_names_for_party_type_name(accounts_parties_role.parties_role.party_type_name)
		role_names = AccountsPartiesRole.role_names_for_party_name_and_party_type_name(accounts_parties_role.parties_role.party_name, accounts_parties_role.parties_role.party_type_name)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (account_id) on related table: accounts
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'account_code',
						:settings => {:list => account_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (parties_role_id) on related table: parties_roles
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'party_type_name',
						:settings => {:list => party_type_names},
						:observer => party_type_name_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'party_name',
						:settings => {:list => party_names},
						:observer => party_name_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'role_name',
						:settings => {:list => role_names}}
 
	build_form(accounts_parties_role,field_configs,action,'accounts_parties_role',caption,is_edit)

end
 
 
 def build_accounts_parties_role_search_form(accounts_parties_role,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:accounts_parties_role_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["accounts_parties_role_party_type_name","accounts_parties_role_party_name","accounts_parties_role_role_name","accounts_parties_role_account_code"])
	#Observers for search combos
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'accounts_parties_role_party_type_name_search_combo_changed',
					 :on_completed_js => search_combos_js["accounts_parties_role_party_type_name"]}

	session[:accounts_parties_role_search_form][:party_type_name_observer] = party_type_name_observer

	party_name_observer  = {:updated_field_id => "role_name_cell",
					 :remote_method => 'accounts_parties_role_party_name_search_combo_changed',
					 :on_completed_js => search_combos_js["accounts_parties_role_party_name"]}

	session[:accounts_parties_role_search_form][:party_name_observer] = party_name_observer

	role_name_observer  = {:updated_field_id => "account_code_cell",
					 :remote_method => 'accounts_parties_role_role_name_search_combo_changed',
					 :on_completed_js => search_combos_js["accounts_parties_role_role_name"]}

	session[:accounts_parties_role_search_form][:role_name_observer] = role_name_observer

 
	party_type_names = AccountsPartiesRole.find_by_sql('select distinct party_type_name from accounts_parties_roles').map{|g|[g.party_type_name]}
	party_type_names.unshift("<empty>")
	if is_flat_search
		party_names = AccountsPartiesRole.find_by_sql('select distinct party_name from accounts_parties_roles').map{|g|[g.party_name]}
		party_names.unshift("<empty>")
		role_names = AccountsPartiesRole.find_by_sql('select distinct role_name from accounts_parties_roles').map{|g|[g.role_name]}
		role_names.unshift("<empty>")
		account_codes = AccountsPartiesRole.find_by_sql('select distinct account_code from accounts_parties_roles').map{|g|[g.account_code]}
		account_codes.unshift("<empty>")
		party_type_name_observer = nil
		party_name_observer = nil
		role_name_observer = nil
	else
		 party_names = ["Select a value from party_type_name"]
		 role_names = ["Select a value from party_name"]
		 account_codes = ["Select a value from role_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'party_type_name',
						:settings => {:list => party_type_names},
						:observer => party_type_name_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'party_name',
						:settings => {:list => party_names},
						:observer => party_name_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'role_name',
						:settings => {:list => role_names},
						:observer => role_name_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'account_code',
						:settings => {:list => account_codes}}
 
	build_form(accounts_parties_role,field_configs,action,'accounts_parties_role',caption,false)

end



 def build_accounts_parties_role_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'account_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'party_name'}
	column_configs[2] = {:field_type => 'text',:field_name => 'party_type_name'}
	column_configs[3] = {:field_type => 'text',:field_name => 'role_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit accounts_parties_role',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_accounts_parties_role',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete accounts_parties_role',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_accounts_parties_role',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 
 
 #=================
 #ACCOUNT TYPE CODE
 #=================
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
 #============
 #ACCOUNT CODE
 #============
 
 def build_account_form(account,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:account_form]= Hash.new
	account_type_names = AccountType.find_by_sql('select distinct account_type_name from account_types').map{|g|[g.account_type_name]}
	account_type_names.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'account_code'}

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (account_type_id) on related table: account_types
#	-----------------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'account_type_name',
						:settings => {:list => account_type_names}}

 
	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'account_description'}


	build_form(account,field_configs,action,'account',caption,is_edit)

end
 
 
 def build_account_search_form(account,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:account_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["account_account_code"])
	#Observers for search combos
 
	account_codes = Account.find_by_sql('select distinct account_code from accounts').map{|g|[g.account_code]}
	account_codes.unshift("<empty>")
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
						:field_name => 'account_code',
						:settings => {:list => account_codes}}
 
	build_form(account,field_configs,action,'account',caption,false)

end



 def build_account_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'account_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'account_description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'account_type_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit account',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_account',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete account',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_account',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
