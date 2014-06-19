module PartyManager::ContactMethodsPartyHelper
 
 
 def build_contact_methods_party_form(contact_methods_party,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:contact_methods_party_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: contact_methods
	combos_js_for_contact_methods = gen_combos_clear_js_for_combos(["contact_methods_party_contact_method_type_code","contact_methods_party_contact_method_code"])
	combos_js_for_parties = gen_combos_clear_js_for_combos(["contact_methods_party_party_type_name","contact_methods_party_party_name"])
	#Observers for combos representing the key fields of fkey table: contact_method_id
	#generate javascript for the on_complete ajax event for each combo for fk table: parties
	combos_js_for_contact_methods = gen_combos_clear_js_for_combos(["contact_methods_party_contact_method_type_code","contact_methods_party_contact_method_code"])
	combos_js_for_parties = gen_combos_clear_js_for_combos(["contact_methods_party_party_type_name","contact_methods_party_party_name"])
	#Observers for combos representing the key fields of fkey table: party_id
	contact_method_type_code_observer  = {:updated_field_id => "contact_method_code_cell",
					 :remote_method => 'contact_methods_party_contact_method_type_code_changed',
					 :on_completed_js => combos_js_for_contact_methods ["contact_methods_party_contact_method_type_code"]}

	session[:contact_methods_party_form][:contact_method_type_code_observer] = contact_method_type_code_observer

#	combo lists for table: contact_methods

	contact_method_type_codes = nil 
	contact_method_codes = nil 
 
	contact_method_type_codes = ContactMethodsParty.get_all_contact_method_type_codes
	if contact_methods_party == nil||is_create_retry
		 contact_method_codes = ["Select a value from contact_method_type_code"]
	else
		contact_method_codes = ContactMethodsParty.contact_method_codes_for_contact_method_type_code(contact_methods_party.contact_method.contact_method_type_code)
	end
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'contact_methods_party_party_type_name_changed',
					 :on_completed_js => combos_js_for_parties ["contact_methods_party_party_type_name"]}

	session[:contact_methods_party_form][:party_type_name_observer] = party_type_name_observer

#	combo lists for table: parties

	party_type_names = nil 
	party_names = nil 
 
	party_type_names = ContactMethodsParty.get_all_party_type_names
	if contact_methods_party == nil||is_create_retry
		 party_names = ["Select a value from party_type_name"]
	else
		party_names = ContactMethodsParty.party_names_for_party_type_name(contact_methods_party.party.party_type_name)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'DateField',
						:field_name => 'from_date'}

	field_configs[1] = {:field_type => 'DateField',
						:field_name => 'thru_date'}

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'remarks'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (party_id) on related table: parties
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'party_type_name',
						:settings => {:list => party_type_names},
						:observer => party_type_name_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'party_name',
						:settings => {:list => party_names}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (contact_method_id) on related table: contact_methods
#	----------------------------------------------------------------------------------------------
	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'contact_method_type_code',
						:settings => {:list => contact_method_type_codes},
						:observer => contact_method_type_code_observer}
 
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'contact_method_code',
						:settings => {:list => contact_method_codes}}
 
	build_form(contact_methods_party,field_configs,action,'contact_methods_party',caption,is_edit)

end
 
 
 def build_contact_methods_party_search_form(contact_methods_party,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:contact_methods_party_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["contact_methods_party_party_type_name","contact_methods_party_party_name","contact_methods_party_contact_method_type_code","contact_methods_party_contact_method_code"])
	#Observers for search combos
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'contact_methods_party_party_type_name_search_combo_changed',
					 :on_completed_js => search_combos_js["contact_methods_party_party_type_name"]}

	session[:contact_methods_party_search_form][:party_type_name_observer] = party_type_name_observer

	party_name_observer  = {:updated_field_id => "contact_method_type_code_cell",
					 :remote_method => 'contact_methods_party_party_name_search_combo_changed',
					 :on_completed_js => search_combos_js["contact_methods_party_party_name"]}

	session[:contact_methods_party_search_form][:party_name_observer] = party_name_observer

	contact_method_type_code_observer  = {:updated_field_id => "contact_method_code_cell",
					 :remote_method => 'contact_methods_party_contact_method_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["contact_methods_party_contact_method_type_code"]}

	session[:contact_methods_party_search_form][:contact_method_type_code_observer] = contact_method_type_code_observer

 
	party_type_names = ContactMethodsParty.find_by_sql('select distinct party_type_name from contact_methods_parties').map{|g|[g.party_type_name]}
	party_type_names.unshift("<empty>")
	if is_flat_search
		party_names = ContactMethodsParty.find_by_sql('select distinct party_name from contact_methods_parties').map{|g|[g.party_name]}
		party_names.unshift("<empty>")
		contact_method_type_codes = ContactMethodsParty.find_by_sql('select distinct contact_method_type_code from contact_methods_parties').map{|g|[g.contact_method_type_code]}
		contact_method_type_codes.unshift("<empty>")
		contact_method_codes = ContactMethodsParty.find_by_sql('select distinct contact_method_code from contact_methods_parties').map{|g|[g.contact_method_code]}
		contact_method_codes.unshift("<empty>")
		party_type_name_observer = nil
		party_name_observer = nil
		contact_method_type_code_observer = nil
	else
		 party_names = ["Select a value from party_type_name"]
		 contact_method_type_codes = ["Select a value from party_name"]
		 contact_method_codes = ["Select a value from contact_method_type_code"]
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
						:field_name => 'contact_method_type_code',
						:settings => {:list => contact_method_type_codes},
						:observer => contact_method_type_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'contact_method_code',
						:settings => {:list => contact_method_codes}}
 
	build_form(contact_methods_party,field_configs,action,'contact_methods_party',caption,false)

end



 def build_contact_methods_party_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'party_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'contact_method_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'from_date'}
	column_configs[3] = {:field_type => 'text',:field_name => 'thru_date'}
	column_configs[4] = {:field_type => 'text',:field_name => 'remarks'}
	column_configs[5] = {:field_type => 'text',:field_name => 'contact_method_type_code'}
	column_configs[6] = {:field_type => 'text',:field_name => 'party_type_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit contact_methods_party',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_contact_methods_party',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete contact_methods_party',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_contact_methods_party',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
