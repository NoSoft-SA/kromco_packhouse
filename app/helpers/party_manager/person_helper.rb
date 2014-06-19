module PartyManager::PersonHelper
 
 
 def build_person_form(person,action,caption,is_edit = nil,is_create_retry = nil)


	titles = ["mr","mrs","dr"]
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'first_name'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'last_name'}

	field_configs[2] = {:field_type => 'DropDownField',
						:field_name => 'title',
						:settings => {:list => titles,:prompt => 'select a title'}}

	field_configs[3] = {:field_type => 'DateField',
						:field_name => 'date_of_birth'}

	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'maiden_name'}

	build_form(person,field_configs,action,'person',caption,is_edit)

end
 
 
 def build_person_search_form(person,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:person_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["person_first_name","person_last_name"])
	#Observers for search combos
	first_name_observer  = {:updated_field_id => "last_name_cell",
					 :remote_method => 'person_first_name_search_combo_changed',
					 :on_completed_js => search_combos_js["person_first_name"]}

	session[:person_search_form][:first_name_observer] = first_name_observer

 
	first_names = Person.find_by_sql('select distinct first_name from people').map{|g|[g.first_name]}
	first_names.unshift("<empty>")
	if is_flat_search
		last_names = Person.find_by_sql('select distinct last_name from people').map{|g|[g.last_name]}
		last_names.unshift("<empty>")
		first_name_observer = nil
	else
		 last_names = ["Select a value from first_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'first_name',
						:settings => {:list => first_names},
						:observer => first_name_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'last_name',
						:settings => {:list => last_names}}
 
	build_form(person,field_configs,action,'person',caption,false)

end



 def build_person_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'first_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'last_name'}
	column_configs[2] = {:field_type => 'text',:field_name => 'title'}
	column_configs[3] = {:field_type => 'text',:field_name => 'date_of_birth'}
	column_configs[4] = {:field_type => 'text',:field_name => 'maiden_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit person',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_person',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete person',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_person',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
