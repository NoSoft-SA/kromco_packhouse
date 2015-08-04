module PartyManager::PartiesRoleHelper
 
 
 def build_role_form(role,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:role_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'role_name'}

	build_form(role,field_configs,action,'role',caption,is_edit)

end
 
  
 def build_role_search_form(role,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:role_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["role_role_name"])
	#Observers for search combos
 
	role_names = Role.find_by_sql('select distinct role_name from roles').map{|g|[g.role_name]}
	role_names.unshift("<empty>")
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
						:field_name => 'role_name',
						:settings => {:list => role_names}}
 
	build_form(role,field_configs,action,'role',caption,false)

end



 def build_role_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'role_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit role',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_role',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete role',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_role',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 #======================
 #PARTIES ROLES CODE
 #======================
 def build_parties_role_form(parties_role,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:parties_role_form]= Hash.new
	role_names = Role.find_by_sql('select distinct role_name from roles').map{|g| g.role_name } - PartiesRole::OWN_CRUD_ROLES
	role_names.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: parties
	combos_js_for_parties = gen_combos_clear_js_for_combos(["parties_role_party_type_name","parties_role_party_name"])
	#Observers for combos representing the key fields of fkey table: party_id
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'parties_role_party_type_name_changed',
					 :on_completed_js => combos_js_for_parties ["parties_role_party_type_name"]}

	session[:parties_role_form][:party_type_name_observer] = party_type_name_observer

#	combo lists for table: parties

	party_type_names = nil 
	party_names = nil 
 
	party_type_names = PartiesRole.get_all_party_type_names
	if parties_role == nil||is_create_retry
		 party_names = ["Select a value from party_type_name"]
     contact_info = ''
	else
		party_names = PartiesRole.party_names_for_party_type_name(parties_role.party.party_type_name)
    contact_info = parties_role.party.formatted_contact_info
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (party_id) on related table: parties
#	----------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'party_type_name',
						:settings => {:list => party_type_names},
						:observer => party_type_name_observer}
 
	field_configs <<  {:field_type => 'DropDownField',
						:field_name => 'party_name',
						:settings => {:list => party_names}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (role_id) on related table: roles
#	----------------------------------------------------------------------------------------------
  if is_edit && PartiesRole::OWN_CRUD_ROLES.include?(parties_role.role_name)
    field_configs << {:field_type => 'TextField',
                      :field_name => 'role_name',
                      :settings   => {:readonly => true}}
  else
    field_configs << {:field_type => 'DropDownField',
              :field_name => 'role_name',
              :settings => {:list => role_names}}
  end

   unless is_edit
     field_configs << {:field_type => 'LabelField',
        :field_name => 'own_crud_note',
        :settings => {:static_value => "NB. Roles #{PartiesRole::OWN_CRUD_ROLES.to_sentence} are created separately via their own menu.",
          :non_dbfield => true, :show_label => false, :css_class => 'unbordered_label_field'}}
   end
 
	field_configs << {:field_type => 'PopupDateSelector',
						:field_name => 'from_date'}

	field_configs << {:field_type => 'PopupDateSelector',
						:field_name => 'to_date'}

	field_configs << {:field_type => 'TextField',
						:field_name => 'remarks'}

  field_configs << {:field_type => 'TextField',
						:field_name => 'sequence_number'}

    field_configs << {:field_type => 'LabelField',
        :field_name => 'contact_info',
        :settings => {:static_value => contact_info,
          :non_dbfield => true, :show_label => true, :css_class => 'unbordered_label_field'}}

	build_form(parties_role,field_configs,action,'parties_role',caption,is_edit)

end
 
 
 def build_parties_role_search_form(parties_role,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:parties_role_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["parties_role_party_type_name","parties_role_party_name","parties_role_role_name"])
	#Observers for search combos
	party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'parties_role_party_type_name_search_combo_changed',
					 :on_completed_js => search_combos_js["parties_role_party_type_name"]}

	session[:parties_role_search_form][:party_type_name_observer] = party_type_name_observer

	party_name_observer  = {:updated_field_id => "role_name_cell",
					 :remote_method => 'parties_role_party_name_search_combo_changed',
					 :on_completed_js => search_combos_js["parties_role_party_name"]}

	session[:parties_role_search_form][:party_name_observer] = party_name_observer

 
	party_type_names = PartiesRole.find_by_sql('select distinct party_type_name from parties_roles').map{|g|[g.party_type_name]}
	party_type_names.unshift("<empty>")
	if is_flat_search
		party_names = PartiesRole.find_by_sql('select distinct party_name from parties_roles').map{|g|[g.party_name]}
		party_names.unshift("<empty>")
		role_names = PartiesRole.find_by_sql('select distinct role_name from parties_roles').map{|g|[g.role_name]}
		role_names.unshift("<empty>")
		party_type_name_observer = nil
		party_name_observer = nil
	else
		 party_names = ["Select a value from party_type_name"]
		 role_names = ["Select a value from party_name"]
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
						:settings => {:list => role_names}}
 
	build_form(parties_role,field_configs,action,'parties_role',caption,false)

end



 def build_parties_role_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'from_date'}
	column_configs[1] = {:field_type => 'text',:field_name => 'to_date'}
	column_configs[2] = {:field_type => 'text',:field_name => 'remarks'}
	column_configs[3] = {:field_type => 'text',:field_name => 'party_name'}
	column_configs[4] = {:field_type => 'text',:field_name => 'party_type_name'}
	column_configs[5] = {:field_type => 'text',:field_name => 'role_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit parties_role',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_parties_role',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete parties_role',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_parties_role',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

  def build_rename_party_form(party,action,caption,is_edit = nil,is_create_retry = nil)
    field_configs = []
    field_configs << {:field_type => 'LabelField',
                      :field_name => 'party_name', :label_caption => 'From name'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'new_name', :non_db_field => true}
    if 'PERSON' == party.party_type_name
      field_configs << {:field_type => 'TextField',
                        :field_name => 'new_first_name'}
      field_configs << {:field_type => 'TextField',
                        :field_name => 'new_last_name'}
    end

    build_form(party,field_configs,action,'party',caption,is_edit)

  end

end
