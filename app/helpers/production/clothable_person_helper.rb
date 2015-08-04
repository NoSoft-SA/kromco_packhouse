module Production::ClothablePersonHelper
 
 
 def build_clothable_person_form(clothable_person,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:clothable_person_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = []
	field_configs << {:field_type => 'TextField',
						:field_name => 'clock_code'}

	field_configs << {:field_type => 'TextField',
						:field_name => 'first_name_code'}

	field_configs << {:field_type => 'TextField',
						:field_name => 'surname_code'}

	field_configs << {:field_type => 'CheckBox',
						:field_name => 'seasonal'}

	field_configs << {:field_type => 'CheckBox',
						:field_name => 'active'}

	build_form(clothable_person,field_configs,action,'clothable_person',caption,is_edit)

end
 
 
 def build_clothable_person_search_form(clothable_person,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:clothable_person_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["clothable_person_clock_code"])
	#Observers for search combos
 
	clock_codes = ClothablePerson.find_by_sql('select distinct clock_code from clothable_people').map{|g|[g.clock_code]}
	clock_codes.unshift("<empty>")
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
						:field_name => 'clock_code',
						:settings => {:list => clock_codes}}
 
	build_form(clothable_person,field_configs,action,'clothable_person',caption,false)

end



 def build_clothable_person_grid(data_set,can_edit,can_delete)

	column_configs = []
	column_configs << {:field_type => 'text',:field_name => 'clock_code'}
	column_configs << {:field_type => 'text',:field_name => 'first_name_code'}
	column_configs << {:field_type => 'text',:field_name => 'surname_code'}
	column_configs << {:field_type => 'text',:field_name => 'seasonal'}
	column_configs << {:field_type => 'text',:field_name => 'active'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs << {:field_type => 'action',:field_name => 'edit clothable_person',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_clothable_person',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete clothable_person',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_clothable_person',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
