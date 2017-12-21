module PartyManager::FarmHelper
 
 #=================
 #FARM PUC ACCOUNT
 #=================
 def build_farm_puc_account_form(farm_puc_account,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:farm_puc_account_form]= Hash.new
	farm_codes = Farm.find_by_sql('select distinct farm_code from farms').map{|g|[g.farm_code]}
	farm_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: accounts_parties_roles
	combos_js_for_accounts_parties_roles = gen_combos_clear_js_for_combos(["farm_puc_account_party_type_name","farm_puc_account_party_name","farm_puc_account_role_name","farm_puc_account_account_code"])
	combos_js_for_pucs = gen_combos_clear_js_for_combos(["farm_puc_account_puc_type_code","farm_puc_account_puc_code"])
	#Observers for combos representing the key fields of fkey table: accounts_parties_role_id
	#generate javascript for the on_complete ajax event for each combo for fk table: pucs
	combos_js_for_accounts_parties_roles = gen_combos_clear_js_for_combos(["farm_puc_account_party_type_name","farm_puc_account_party_name","farm_puc_account_role_name","farm_puc_account_account_code"])
	combos_js_for_pucs = gen_combos_clear_js_for_combos(["farm_puc_account_puc_type_code","farm_puc_account_puc_code"])
	#Observers for combos representing the key fields of fkey table: puc_id
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'farm_puc_account_party_type_name_changed',
					 :on_completed_js => combos_js_for_accounts_parties_roles ["farm_puc_account_party_type_name"]}

	session[:farm_puc_account_form][:party_type_name_observer] = party_type_name_observer

	party_name_observer  = {:updated_field_id => "role_name_cell",
					 :remote_method => 'farm_puc_account_party_name_changed',
					 :on_completed_js => combos_js_for_accounts_parties_roles ["farm_puc_account_party_name"]}

	session[:farm_puc_account_form][:party_name_observer] = party_name_observer

	role_name_observer  = {:updated_field_id => "account_code_cell",
					 :remote_method => 'farm_puc_account_role_name_changed',
					 :on_completed_js => combos_js_for_accounts_parties_roles ["farm_puc_account_role_name"]}

	session[:farm_puc_account_form][:role_name_observer] = role_name_observer

#	combo lists for table: accounts_parties_roles

	party_type_names = nil 
	party_names = nil 
	role_names = nil 
	account_codes = nil 
 
	party_type_names = FarmPucAccount.get_all_party_type_names
	party_type_names.unshift("<empty>")
	if farm_puc_account == nil||is_create_retry
		 party_names = ["Select a value from party_type_name"]
		 role_names = ["Select a value from party_name"]
		 account_codes = ["Select a value from role_name"]
	else
		party_names = FarmPucAccount.party_names_for_party_type_name(farm_puc_account.accounts_parties_role.party_type_name)
		role_names = FarmPucAccount.role_names_for_party_name_and_party_type_name(farm_puc_account.accounts_parties_role.party_name, farm_puc_account.accounts_parties_role.party_type_name)
		account_codes = FarmPucAccount.account_codes_for_role_name_and_party_name_and_party_type_name(farm_puc_account.accounts_parties_role.role_name, farm_puc_account.accounts_parties_role.party_name, farm_puc_account.accounts_parties_role.party_type_name)
	end
	puc_type_code_observer  = {:updated_field_id => "puc_code_cell",
					 :remote_method => 'farm_puc_account_puc_type_code_changed',
					 :on_completed_js => combos_js_for_pucs ["farm_puc_account_puc_type_code"]}

	session[:farm_puc_account_form][:puc_type_code_observer] = puc_type_code_observer

#	combo lists for table: pucs

	puc_type_codes = nil 
	puc_codes = nil 
 
	puc_type_codes = FarmPucAccount.get_all_puc_type_codes
	puc_type_codes.unshift("<empty>")
	if farm_puc_account == nil||is_create_retry
		 puc_codes = ["Select a value from puc_type_code"]
	else
		puc_codes = FarmPucAccount.puc_codes_for_puc_type_code(farm_puc_account.puc.puc_type_code)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'DateField',
						:field_name => 'from_date'}

	field_configs[1] = {:field_type => 'DateField',
						:field_name => 'thru_date'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (farm_id) on related table: farms
#	----------------------------------------------------------------------------------------------
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'farm_code',
						:settings => {:list => farm_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (puc_id) on related table: pucs
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'puc_type_code',
						:settings => {:list => puc_type_codes},
						:observer => puc_type_code_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'puc_code',
						:settings => {:list => puc_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (accounts_parties_role_id) on related table: accounts_parties_roles
#	----------------------------------------------------------------------------------------------
	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'party_type_name',
						:settings => {:list => party_type_names},
						:observer => party_type_name_observer}
 
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'party_name',
						:settings => {:list => party_names},
						:observer => party_name_observer}
 
	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'role_name',
						:settings => {:list => role_names},
						:observer => role_name_observer}
 
	field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'account_code',
						:settings => {:list => account_codes}}
 
	build_form(farm_puc_account,field_configs,action,'farm_puc_account',caption,is_edit)

end
 
 
 def build_farm_puc_account_search_form(farm_puc_account,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:farm_puc_account_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["farm_puc_account_party_type_name","farm_puc_account_party_name","farm_puc_account_role_name","farm_puc_account_account_code","farm_puc_account_puc_type_code","farm_puc_account_puc_code","farm_puc_account_farm_code"])
	#Observers for search combos
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'farm_puc_account_party_type_name_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_puc_account_party_type_name"]}

	session[:farm_puc_account_search_form][:party_type_name_observer] = party_type_name_observer

	party_name_observer  = {:updated_field_id => "role_name_cell",
					 :remote_method => 'farm_puc_account_party_name_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_puc_account_party_name"]}

	session[:farm_puc_account_search_form][:party_name_observer] = party_name_observer

	role_name_observer  = {:updated_field_id => "account_code_cell",
					 :remote_method => 'farm_puc_account_role_name_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_puc_account_role_name"]}

	session[:farm_puc_account_search_form][:role_name_observer] = role_name_observer

	account_code_observer  = {:updated_field_id => "puc_type_code_cell",
					 :remote_method => 'farm_puc_account_account_code_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_puc_account_account_code"]}

	session[:farm_puc_account_search_form][:account_code_observer] = account_code_observer

	puc_type_code_observer  = {:updated_field_id => "puc_code_cell",
					 :remote_method => 'farm_puc_account_puc_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_puc_account_puc_type_code"]}

	session[:farm_puc_account_search_form][:puc_type_code_observer] = puc_type_code_observer

	puc_code_observer  = {:updated_field_id => "farm_code_cell",
					 :remote_method => 'farm_puc_account_puc_code_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_puc_account_puc_code"]}

	session[:farm_puc_account_search_form][:puc_code_observer] = puc_code_observer

 
	party_type_names = FarmPucAccount.find_by_sql('select distinct party_type_name from farm_puc_accounts').map{|g|[g.party_type_name]}
	party_type_names.unshift("<empty>")
	if is_flat_search
		party_names = FarmPucAccount.find_by_sql('select distinct party_name from farm_puc_accounts').map{|g|[g.party_name]}
		party_names.unshift("<empty>")
		role_names = FarmPucAccount.find_by_sql('select distinct role_name from farm_puc_accounts').map{|g|[g.role_name]}
		role_names.unshift("<empty>")
		account_codes = FarmPucAccount.find_by_sql('select distinct account_code from farm_puc_accounts').map{|g|[g.account_code]}
		account_codes.unshift("<empty>")
		puc_type_codes = FarmPucAccount.find_by_sql('select distinct puc_type_code from farm_puc_accounts').map{|g|[g.puc_type_code]}
		puc_type_codes.unshift("<empty>")
		puc_codes = FarmPucAccount.find_by_sql('select distinct puc_code from farm_puc_accounts').map{|g|[g.puc_code]}
		puc_codes.unshift("<empty>")
		farm_codes = FarmPucAccount.find_by_sql('select distinct farm_code from farm_puc_accounts').map{|g|[g.farm_code]}
		farm_codes.unshift("<empty>")
		party_type_name_observer = nil
		party_name_observer = nil
		role_name_observer = nil
		account_code_observer = nil
		puc_type_code_observer = nil
		puc_code_observer = nil
	else
		 party_names = ["Select a value from party_type_name"]
		 role_names = ["Select a value from party_name"]
		 account_codes = ["Select a value from role_name"]
		 puc_type_codes = ["Select a value from account_code"]
		 puc_codes = ["Select a value from puc_type_code"]
		 farm_codes = ["Select a value from puc_code"]
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
						:settings => {:list => account_codes},
						:observer => account_code_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'puc_type_code',
						:settings => {:list => puc_type_codes},
						:observer => puc_type_code_observer}
 
	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'puc_code',
						:settings => {:list => puc_codes},
						:observer => puc_code_observer}
 
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'farm_code',
						:settings => {:list => farm_codes}}
 
	build_form(farm_puc_account,field_configs,action,'farm_puc_account',caption,false)

end



 def build_orchard_grid(data_set,can_edit,can_delete)
	column_configs = Array.new
	column_configs << {:field_type => 'text',:field_name => 'orchard_code', :column_width=>150}
	column_configs << {:field_type => 'text',:field_name => 'orchard_description',:column_caption=>'description'}
	column_configs << {:field_type => 'text',:field_name => 'commodity'}
	column_configs << {:field_type => 'text',:field_name => 'rmt_variety', :column_width=>200}
	column_configs << {:field_type => 'text',:field_name => 'id'}

	if @single_childed
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'remove',
																							 :settings =>
																									 {:link_text => 'remove',
																										:target_action => 'remove_child_orchard',
																										:id_column => 'id'}}
	end

	@multi_select = "selected_products"
  return get_data_grid(data_set,column_configs,MesScada::GridPlugins::PartyManager::OrchardsGridPlugin.new)
 end
 
 #===============
 #FARM GROUP CODE
 #===============
 def build_farm_group_form(farm_group,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:farm_group_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'farm_group_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'farm_group_name'}

	build_form(farm_group,field_configs,action,'farm_group',caption,is_edit)

end
 
 
 def build_farm_group_search_form(farm_group,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:farm_group_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["farm_group_farm_group_code"])
	#Observers for search combos
 
	farm_group_codes = FarmGroup.find_by_sql('select distinct farm_group_code from farm_groups').map{|g|[g.farm_group_code]}
	farm_group_codes.unshift("<empty>")
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
						:field_name => 'farm_group_code',
						:settings => {:list => farm_group_codes}}
 
	build_form(farm_group,field_configs,action,'farm_group',caption,false)

end



 def build_farm_group_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'farm_group_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'farm_group_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit farm_group',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_farm_group',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete farm_group',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_farm_group',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 #========
 #PUC CODE
 #========
 def build_puc_form(puc,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:puc_form]= Hash.new
	puc_type_codes = PucType.find_by_sql('select distinct puc_type_code from puc_types').map{|g|[g.puc_type_code]}
	puc_type_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'puc_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'description'}
						
	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'nature_choice_certificate_code'}					

	field_configs[3] = {:field_type => 'TextField',
						:field_name => 'eurogap_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (puc_type_id) on related table: puc_types
#	----------------------------------------------------------------------------------------------
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'puc_type_code',
						:settings => {:list => puc_type_codes}}
 
	build_form(puc,field_configs,action,'puc',caption,is_edit)

end
 
 
 def build_puc_search_form(puc,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:puc_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["puc_puc_type_code","puc_puc_code"])
	#Observers for search combos
	puc_type_code_observer  = {:updated_field_id => "puc_code_cell",
					 :remote_method => 'puc_puc_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["puc_puc_type_code"]}

	session[:puc_search_form][:puc_type_code_observer] = puc_type_code_observer

 
	puc_type_codes = Puc.find_by_sql('select distinct puc_type_code from pucs').map{|g|[g.puc_type_code]}
	puc_type_codes.unshift("<empty>")
	if is_flat_search
		puc_codes = Puc.find_by_sql('select distinct puc_code from pucs').map{|g|[g.puc_code]}
		puc_codes.unshift("<empty>")
		puc_type_code_observer = nil
	else
		 puc_codes = ["Select a value from puc_type_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'puc_type_code',
						:settings => {:list => puc_type_codes},
						:observer => puc_type_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'puc_code',
						:settings => {:list => puc_codes}}
 
	build_form(puc,field_configs,action,'puc',caption,false)

end

 
 def build_puc_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'puc_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'puc_type_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'description'}
	column_configs[3] = {:field_type => 'text',:field_name => 'eurogap_code'}
	column_configs[4] = {:field_type => 'text',:field_name => 'nature_choice_certificate_code'}
	
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit puc',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_puc',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete puc',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_puc',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 
 #================
 #PUC TYPE CODE
 #================
 def build_puc_type_form(puc_type,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:puc_type_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'puc_type_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'description'}

	build_form(puc_type,field_configs,action,'puc_type',caption,is_edit)

end
 
 
 def build_puc_type_search_form(puc_type,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:puc_type_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["puc_type_puc_type_code"])
	#Observers for search combos
 
	puc_type_codes = PucType.find_by_sql('select distinct puc_type_code from puc_types').map{|g|[g.puc_type_code]}
	puc_type_codes.unshift("<empty>")
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
						:field_name => 'puc_type_code',
						:settings => {:list => puc_type_codes}}
 
	build_form(puc_type,field_configs,action,'puc_type',caption,false)

end



 def build_puc_type_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'puc_type_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit puc_type',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_puc_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete puc_type',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_puc_type',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 #==========
 #FARM CODE
 #==========
 def build_farm_form(farm,action,caption,farm_orchards,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:farm_form]= Hash.new
	farm_group_codes = FarmGroup.find_by_sql('select distinct farm_group_code from farm_groups').map{|g|[g.farm_group_code]}
	farm_group_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: parties_roles
	combos_js_for_parties_roles = gen_combos_clear_js_for_combos(["farm_party_type_name","farm_party_name","farm_role_name"])
	#Observers for combos representing the key fields of fkey table: parties_role_id
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'farm_party_type_name_changed',
					 :on_completed_js => combos_js_for_parties_roles ["farm_party_type_name"]}

	session[:farm_form][:party_type_name_observer] = party_type_name_observer

	party_name_observer  = {:updated_field_id => "role_name_cell",
					 :remote_method => 'farm_party_name_changed',
					 :on_completed_js => combos_js_for_parties_roles ["farm_party_name"]}

	session[:farm_form][:party_name_observer] = party_name_observer

#	combo lists for table: parties_roles

	party_type_names = nil 
	party_names = nil 
	role_names = nil 

  farm_owners = PartiesRole.find_by_sql("select parties_roles.id,parties.party_name from parties,parties_roles where parties_roles.role_name='FARM_OWNER' and parties_roles.party_id=parties.id").map{|f| [f.party_name, f.id]}

	party_type_names = Farm.get_all_party_type_names
	if farm == nil||is_create_retry
		 party_names = ["Select a value from party_type_name"]
		 role_names = ["Select a value from party_name"]
	else
		party_names = Farm.party_names_for_party_type_name(farm.parties_role.party_type_name)
		role_names = Farm.role_names_for_party_name_and_party_type_name(farm.parties_role.party_name, farm.parties_role.party_type_name)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (parties_role_id) on related table: parties_roles
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'party_type_name',
						:settings => {:list => party_type_names},
						:observer => party_type_name_observer}
 
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'party_name',
						:settings => {:list => party_names},
						:observer => party_name_observer}
 
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'role_name',
						:settings => {:list => role_names}}

   field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'farm_owner',
						:settings => {:list => farm_owners}}
 
	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'farm_code'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'farm_description'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'farm_area'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'max_empty_bins'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'bin_availability_factor'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'gap'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'remark1_ptlocation'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'remark2_ptaccount'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (farm_group_id) on related table: farm_groups
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'farm_group_code',
						:settings => {:list => farm_group_codes}}
 
 
#-------------------------------------------------------------------------------------------------
#     Happymore's Additional code
#-------------------------------------------------------------------------------------------------
    if is_edit
        field_configs[field_configs.length()] = {:field_type => 'LabelField',
                            :field_name => 'orchards',
                            :settings =>{:static_value =>'ORCHARDS'}}
                            
        if farm!=nil
          # orchards = Orchard.find(:all, :conditions =>["farm_id = ?", farm.id])

          #MM102014 - show orchard orchard_description,commodity and rmt variety
          orchards =Orchard.find_by_sql("select distinct orchards.id,orchards.orchard_code,orchards.orchard_description,commodities.commodity_description_long as commodity, rmt_varieties.rmt_variety_description as rmt_variety
																				from orchards
                                        left outer join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id
                                        left outer join commodities on rmt_varieties.commodity_id = commodities.id
                                        where farm_id = #{farm.id} and orchards.parent_orchard_id is null and (orchards.is_group is false or orchards.is_group is null)
																				group by orchards.id,orchard_code,orchard_description, commodity, rmt_variety")
          orchards.each {|orchard|
            link_text =  "#{orchard.orchard_code.to_s} - #{orchard.orchard_description.to_s} ( #{orchard.commodity.to_s} , #{orchard.rmt_variety.to_s} )"

						new_link_text = "<a href='/party_manager/farm/edit_orchard/#{orchard.id}' class='action_link' onclick='show_action_image(this);'>#{link_text}</a>  &nbsp&nbsp&nbsp "
						new_link_text += "<a href='/party_manager/farm/set_orchard_as_group/#{orchard.id}' class='action_link' onclick='show_action_image(this);'>set_orchard_as_group</a>"
						new_link_text += "<img align='absmiddle' alt='Loading' border='0' id='form_link_loading_img' src='/images/loading.gif' style='visibility: hidden;' />"
            field_configs[field_configs.length()] = {:field_type =>'LabelField',  :field_name =>'',
                                                     :settings =>{:static_value =>"#{new_link_text}", :css_class =>'orchards'}}
          }

        end

        field_configs[field_configs.length()] = {:field_type =>'LinkField', :field_name =>'new orchard',
                            :settings =>{:link_text => 'new orchard',
                                         :target_action =>'new_orchard',
                                         :css_class =>'new_heading'}}

				field_configs[field_configs.length()] = {:field_type => 'LabelField',
																								 :field_name => 'parent_orchards',
																								 :settings =>{:static_value =>'ORCHARD GROUPS'}}
				if farm!=nil
					parent_orchards =Orchard.find_by_sql("select orchards.* ,commodities.commodity_description_long as commodity, rmt_varieties.rmt_variety_description as rmt_variety
																				from orchards
                                        left outer join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id
                                        left outer join commodities on rmt_varieties.commodity_id = commodities.id
                                        where farm_id = #{farm.id} and (orchards.is_group is TRUE)")
					parent_orchards.each {|orchard|
						link_text =  "#{orchard.orchard_code.to_s} - #{orchard.orchard_description.to_s} ( #{orchard.commodity.to_s} , #{orchard.rmt_variety.to_s} )"
						new_link_text = "<a href='/party_manager/farm/edit_orchard/#{orchard.id}' class='action_link' onclick='show_action_image(this);'>#{link_text}</a>  &nbsp&nbsp&nbsp "
						new_link_text += "<a href='/party_manager/farm/view_child_orchards/#{orchard.id}' class='action_link' onclick='show_action_image(this);'>manage</a> &nbsp&nbsp&nbsp "
						new_link_text += "<a href='/party_manager/farm/remove_orchard_as_parent/#{orchard.id}' class='action_link' onclick='show_action_image(this);'><img title=\"remove as group\" style='height: 12px;' src='/images/delete.png'/></a>  &nbsp&nbsp&nbsp "
						new_link_text += "<img align='absmiddle' alt='Loading' border='0' id='form_link_loading_img' src='/images/loading.gif' style='visibility: hidden;' />"
						field_configs[field_configs.length()] = {:field_type =>'LabelField',  :field_name =>'',
																										 :settings =>{:static_value =>"#{new_link_text}", :css_class =>'orchards'}}
					}

				end


		end
#-------------------------------------------------------------------------------------------------
#     End of Happymore's Additional Code
#-------------------------------------------------------------------------------------------------
    
	build_form(farm,field_configs,action,'farm',caption,is_edit)

end


#-------------------------------------------------------------------------------------------------
#     Happymore's Additional code
#-------------------------------------------------------------------------------------------------

def build_orchard_form(orchard,action,caption,is_edit = nil,is_create_retry = nil)
    
    #-------------------------------------------------
    #   Define form fields
    #-------------------------------------------------
     field_configs = Array.new

     orchard_commodity_id = Commodity.find_by_sql("select * from commodities").map{|g|["#{g.commodity_code} - #{g.commodity_description_long}", g.id]}
		 parent_orchards = Orchard.find_by_sql("select * from orchards where farm_id=#{session[:farm_record].id} and (is_group is true)")
		 parent_orchard_ids = !parent_orchards.empty? ? parent_orchards.map{|g|[g.orchard_code, g.id]} : []
     orchard_rmt_variety_id = ["Select a value from commodity_code"]

		 session[:orchard_form]= Hash.new
		 search_combos_js = gen_combos_clear_js_for_combos(["orchard_parent_orchard_id","orchard_orchard_commodity_id","orchard_orchard_rmt_variety_id"])
	   parent_orchard_id_observer  = {:updated_field_id => "orchard_commodity_id_cell",
																	:remote_method => 'orchard_parent_orchard_id_search_combo_changed',
																	:on_completed_js => search_combos_js["orchard_parent_orchard_id"]}
		 session[:orchard_form][:parent_orchard_id_observer] = parent_orchard_id_observer

	   orchard_commodity_id_observer  = {:updated_field_id => "orchard_rmt_variety_id_cell",
																		:remote_method => 'orchard_commodity_id_search_combo_changed',
																		:on_completed_js => search_combos_js["orchard_orchard_commodity_id"]}
		 session[:orchard_form][:orchard_commodity_id_observer] = orchard_commodity_id_observer

	   field_configs <<  {:field_type => 'DropDownField',
												:field_name => 'parent_orchard_id',
												:non_db_field => true,
												:settings => {:list => parent_orchard_ids, :label_caption => 'parent orchard code'},
												:observer => parent_orchard_id_observer}

     field_configs <<  {:field_type => 'DropDownField',
                        :field_name => 'orchard_commodity_id?required',
                        :non_db_field => true,
                        :settings => {:list => orchard_commodity_id, :label_caption => 'commodity code'},
                        :observer => orchard_commodity_id_observer}

     field_configs <<  {:field_type => 'DropDownField',
                        :field_name => 'orchard_rmt_variety_id?required',
                        :settings => {:list => orchard_rmt_variety_id, :label_caption => 'rmt variety code'}}

     field_configs << {:field_type =>'TextField', :field_name =>'orchard_code'}

     field_configs << {:field_type =>'TextField', :field_name =>'orchard_description'}

     # field_configs[0] = {:field_type =>'TextField', :field_name =>'orchard_code'}
     # field_configs[field_configs.length()] = {:field_type =>'TextField', :field_name =>'orchard_description'}
     
     build_form(orchard,field_configs,action,'orchard',caption,is_edit)
     
end

def build_edit_orchard_form(orchard,action,caption,is_edit=nil,is_create_retry=nil)
    field_configs = Array.new

    #MM102014 - add Commodities and rmt varieties
    orchard_rmt_variety_id = orchard.orchard_rmt_variety_id
    if orchard_rmt_variety_id == nil
      orchard_commodity_id_list = Commodity.find_by_sql("select * from commodities").map{|g|["#{g.commodity_code} - #{g.commodity_description_long}", g.id]}
      orchard_rmt_variety_id_list = RmtVariety.find_by_sql("select * from rmt_varieties").map{|g|["#{g.rmt_variety_code} - #{g.rmt_variety_description}", g.id]}
    else
      orchard_commodity = Commodity.find_by_sql("select commodities.* from commodities
                                                inner join rmt_varieties on rmt_varieties.commodity_id = commodities.id
                                                where rmt_varieties.id = #{orchard_rmt_variety_id}")
      if orchard_commodity.empty?
      else
        orchard.orchard_commodity_id = orchard_commodity[0].id
      end

      orchard_commodity_id_list = Commodity.find_by_sql("select * from commodities").map{|g|["#{g.commodity_code} - #{g.commodity_description_long}", g.id]}
      orchard_rmt_variety_id_list = RmtVariety.find_by_sql("select * from rmt_varieties where commodity_id = #{orchard.orchard_commodity_id}").map{|g|["#{g.rmt_variety_code} - #{g.rmt_variety_description}", g.id]}
    end

    # search_combos_js = gen_combos_clear_js_for_combos(["orchard_orchard_commodity_id","orchard_orchard_rmt_variety_id"])
    # orchard_commodity_id_observer  = {:updated_field_id => "orchard_rmt_variety_id_cell",
    #                                   :remote_method => 'orchard_commodity_id_search_combo_changed',
    #                                   :on_completed_js => search_combos_js["orchard_orchard_commodity_id"]}

		session[:orchard_form]= Hash.new
		search_combos_js = gen_combos_clear_js_for_combos(["orchard_parent_orchard_id","orchard_orchard_commodity_id","orchard_orchard_rmt_variety_id"])
		parent_orchard_id_observer  = {:updated_field_id => "orchard_commodity_id_cell",
																	 :remote_method => 'orchard_parent_orchard_id_search_combo_changed',
																	 :on_completed_js => search_combos_js["orchard_parent_orchard_id"]}
		session[:orchard_form][:parent_orchard_id_observer] = parent_orchard_id_observer

		orchard_commodity_id_observer  = {:updated_field_id => "orchard_rmt_variety_id_cell",
																			:remote_method => 'orchard_commodity_id_search_combo_changed',
																			:on_completed_js => search_combos_js["orchard_orchard_commodity_id"]}
		session[:orchard_form][:orchard_commodity_id_observer] = orchard_commodity_id_observer

		if(!orchard.is_group)
			parent_orchard_ids = Orchard.find_by_sql("select * from orchards where (is_group is true and id<>#{orchard.id} and farm_id=#{orchard.farm_id})").map{|g|[g.orchard_code, g.id]}
			field_configs <<  {:field_type => 'DropDownField',
												 :field_name => 'parent_orchard_id',
												 :non_db_field => true,
												 :settings => {:list => parent_orchard_ids, :label_caption => 'parent orchard code'},
												 :observer => parent_orchard_id_observer}
		end

		field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'orchard_commodity_id?required',
                       :non_db_field => true,
                       :settings => {:list => orchard_commodity_id_list, :label_caption => 'commodity_code'},
                       :observer => orchard_commodity_id_observer}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'orchard_rmt_variety_id?required',
                       :settings => {:list => orchard_rmt_variety_id_list, :label_caption => 'rmt_variety_code'}}

    field_configs << {:field_type =>'TextField', :field_name =>'orchard_code'}

    field_configs << {:field_type =>'TextField', :field_name =>'orchard_description'}

		if(!orchard.is_group)
			field_configs[field_configs.length()] = {:field_type =>'LinkField', :field_name =>'',
																								:settings =>{:link_text =>'remove orchard',
																														 :target_action =>'delete_orchard',
																														 :css_class =>'orchards-delete',
																														 :id_column =>'id'}}
		end

    build_form(orchard,field_configs,action,'orchard',caption,is_edit)
end
    
#-------------------------------------------------------------------------------------------------
#     End of Happymore's Additional Code
#-------------------------------------------------------------------------------------------------
 
 
 def build_farm_search_form(farm,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:farm_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["farm_party_type_name","farm_party_name","farm_role_name","farm_farm_group_code","farm_farm_code"])
	#Observers for search combos
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'farm_party_type_name_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_party_type_name"]}

	session[:farm_search_form][:party_type_name_observer] = party_type_name_observer

	party_name_observer  = {:updated_field_id => "role_name_cell",
					 :remote_method => 'farm_party_name_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_party_name"]}

	session[:farm_search_form][:party_name_observer] = party_name_observer

	role_name_observer  = {:updated_field_id => "farm_group_code_cell",
					 :remote_method => 'farm_role_name_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_role_name"]}

	session[:farm_search_form][:role_name_observer] = role_name_observer

	farm_group_code_observer  = {:updated_field_id => "farm_code_cell",
					 :remote_method => 'farm_farm_group_code_search_combo_changed',
					 :on_completed_js => search_combos_js["farm_farm_group_code"]}

	session[:farm_search_form][:farm_group_code_observer] = farm_group_code_observer

 
	party_type_names = Farm.find_by_sql('select distinct party_type_name from farms').map{|g|[g.party_type_name]}
	party_type_names.unshift("<empty>")
	if is_flat_search
		party_names = Farm.find_by_sql('select distinct party_name from farms').map{|g|[g.party_name]}
		party_names.unshift("<empty>")
		role_names = Farm.find_by_sql('select distinct role_name from farms').map{|g|[g.role_name]}
		role_names.unshift("<empty>")
		farm_group_codes = Farm.find_by_sql('select distinct farm_group_code from farms').map{|g|[g.farm_group_code]}
		farm_group_codes.unshift("<empty>")
		farm_codes = Farm.find_by_sql('select distinct farm_code from farms').map{|g|[g.farm_code]}
		farm_codes.unshift("<empty>")
		party_type_name_observer = nil
		party_name_observer = nil
		role_name_observer = nil
		farm_group_code_observer = nil
	else
		 party_names = ["Select a value from party_type_name"]
		 role_names = ["Select a value from party_name"]
		 farm_group_codes = ["Select a value from role_name"]
		 farm_codes = ["Select a value from farm_group_code"]
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
						:field_name => 'farm_group_code',
						:settings => {:list => farm_group_codes},
						:observer => farm_group_code_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'farm_code',
						:settings => {:list => farm_codes}}
 
	build_form(farm,field_configs,action,'farm',caption,false)

end



 def build_farm_grid(data_set,can_edit,can_delete)

  if data_set[0].kind_of?(Hash)
    keys                                    = data_set[0].keys
  else
    keys                                    = data_set[0].attributes.keys
  end

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text', :field_name => keys[keys.index('farm_code')]}
	column_configs[1] = {:field_type => 'text', :field_name => keys[keys.index('farm_description')]}
	column_configs[2] = {:field_type => 'text', :field_name => keys[keys.index('farm_area')]}
	column_configs[3] = {:field_type => 'text', :field_name => keys[keys.index('max_empty_bins')]}
	column_configs[4] = {:field_type => 'text', :field_name => keys[keys.index('bin_availability_factor')]}
	column_configs[5] = {:field_type => 'text', :field_name => keys[keys.index('gap')]}
	column_configs[6] = {:field_type => 'text', :field_name => keys[keys.index('remark1_ptlocation')]}
	column_configs[7] = {:field_type => 'text', :field_name => keys[keys.index('remark2_ptaccount')]}
	column_configs[8] = {:field_type => 'text', :field_name => keys[keys.index('farm_group_code')]}
	column_configs[9] = {:field_type => 'text', :field_name => keys[keys.index('party_name')]}
	column_configs[10] = {:field_type => 'text', :field_name => keys[keys.index('party_type_name')]}
	column_configs[11] = {:field_type => 'text', :field_name => keys[keys.index('role_name')]}
  column_configs[12] = {:field_type => 'text', :field_name => keys[keys.index('farm_owner_code')]}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit farm',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_farm',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete farm',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_farm',
				:id_column => 'id'}}
  end
   
 return get_data_grid(data_set,column_configs,nil,true)
end

end
