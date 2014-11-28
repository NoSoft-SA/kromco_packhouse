module PartyManager::PersonHelper
 
 
 def build_person_form(person,action,caption,is_edit,is_create_retry = nil)


	titles = ["mr","mrs","dr"]

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new

   #MM112014 - messcada changes
   rfid_list = MesscadaRfidAllocation.find_by_sql('select distinct rfid,id from messcada_rfid_allocations').map{|g|["#{g.rfid}", g.rfid]}

   if is_edit
     id = person.id
     industry_number = person.industry_number.to_s
     messcada_values = MesscadaPeopleViewMesscadaRfidAllocation.find_by_sql("SELECT * from messcada_people_view_messcada_rfid_allocations where person_id = #{id} and industry_number = '#{industry_number}'")
     if messcada_values.empty?
     else
       person.rfid = messcada_values[0].rfid
       person.start_date = messcada_values[0].start_date
       person.end_date = messcada_values[0].end_date
       rfid_list.unshift(["#{person.rfid}",person.rfid])
     end
   end

   field_configs << {:field_type => 'TextField',
                     :field_name => 'first_name'}

   field_configs << {:field_type => 'TextField',
                     :field_name => 'last_name'}

   field_configs << {:field_type => 'DropDownField',
                     :field_name => 'title',
                     :settings => {:list => titles,:prompt => 'select a title'}}

   field_configs << {:field_type => 'DateField',
                     :field_name => 'date_of_birth'}

   field_configs <<  {:field_type => 'TextField',
                      :field_name => 'maiden_name'}

   field_configs << {:field_type => 'TextField',
                     :field_name => 'initials'}

   field_configs << {:field_type => 'TextField',
                     :field_name => 'industry_number'}

   field_configs << {:field_type => 'DropDownField',
                     :field_name => 'rfid',
                     :settings => {:list => rfid_list}}

   field_configs << {:field_type => 'PopupDateSelector',
                     :field_name => 'start_date'}

   field_configs << {:field_type => 'PopupDateSelector',
                     :field_name => 'end_date'}

   # field_configs << {:field_type => 'TextField',
   #                   :field_name => 'rfid'}

  # field_configs[0] = {:field_type => 'TextField',
	# 					:field_name => 'first_name'}
  #
	# field_configs[1] = {:field_type => 'TextField',
	# 					:field_name => 'last_name'}
  #
	# field_configs[2] = {:field_type => 'DropDownField',
	# 					:field_name => 'title',
	# 					:settings => {:list => titles,:prompt => 'select a title'}}
  #
	# field_configs[3] = {:field_type => 'DateField',
	# 					:field_name => 'date_of_birth'}
  #
	# field_configs[4] = {:field_type => 'TextField',
	# 					:field_name => 'maiden_name'}

	build_form(person,field_configs,action,'person',caption,is_edit)

end
 
 
 def build_person_search_form(person,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:person_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["person_first_name","person_last_name","person_industry_number"])
	#Observers for search combos
	first_name_observer  = {:updated_field_id => "last_name_cell",
					 :remote_method => 'person_first_name_search_combo_changed',
					 :on_completed_js => search_combos_js["person_first_name"]}

  session[:person_search_form][:first_name_observer] = first_name_observer

  #MM112014 - messcada changes
  last_name_observer  = {:updated_field_id => "industry_number_cell",
                          :remote_method => 'person_last_name_search_combo_changed',
                          :on_completed_js => search_combos_js["person_last_name"]}

  session[:person_search_form][:last_name_observer] = last_name_observer
 
	first_names = Person.find_by_sql('select distinct first_name from people').map{|g|[g.first_name]}
	first_names.unshift("<empty>")
	if is_flat_search
		last_names = Person.find_by_sql('select distinct last_name from people').map{|g|[g.last_name]}
		last_names.unshift("<empty>")
		first_name_observer = nil
    #MM112014 - messcada changes
    industry_numbers = Person.find_by_sql('select distinct industry_number from people').map{|g|[g.industry_number]}
    industry_numbers.unshift("<empty>")
    last_name_observer = nil
	else
		 last_names = ["Select a value from first_name"]
     #MM112014 - messcada changes
     industry_numbers = ["Select a value from first_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
  #MM112014 - messcada changes

  field_configs << {:field_type => 'DropDownField',
                       :field_name => 'first_name',
                       :settings => {:list => first_names},
                       :observer => first_name_observer}

  field_configs << {:field_type => 'DropDownField',
                    :field_name => 'last_name',
                    :settings => {:list => last_names},
                    :observer => last_name_observer}

  field_configs << {:field_type => 'DropDownField',
                       :field_name => 'industry_number',
                       :settings => {:list => industry_numbers}}


  # field_configs[0] =  {:field_type => 'DropDownField',
	# 					:field_name => 'first_name',
	# 					:settings => {:list => first_names},
	# 					:observer => first_name_observer}
  #
	# field_configs[1] =  {:field_type => 'DropDownField',
	# 					:field_name => 'last_name',
	# 					:settings => {:list => last_names}}
 
	build_form(person,field_configs,action,'person',caption,false)

end



 def build_person_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
  #MM112014 - messcada changes
  column_configs << {:field_type => 'text',:field_name => 'first_name'}
  column_configs << {:field_type => 'text',:field_name => 'last_name'}
  column_configs << {:field_type => 'text',:field_name => 'title'}
  column_configs << {:field_type => 'text',:field_name => 'date_of_birth'}
  column_configs << {:field_type => 'text',:field_name => 'maiden_name'}
  column_configs << {:field_type => 'text',:field_name => 'initials'}
  column_configs << {:field_type => 'text',:field_name => 'industry_number'}
  column_configs << {:field_type => 'text',:field_name => 'messcada_people_view_messcada_rfid_allocation.rfid '}
  column_configs << {:field_type => 'text',:field_name => 'messcada_people_view_messcada_rfid_allocation.start_date'}
  column_configs << {:field_type => 'text',:field_name => 'messcada_people_view_messcada_rfid_allocation.end_date'}

  # column_configs[0] = {:field_type => 'text',:field_name => 'first_name'}
	# column_configs[1] = {:field_type => 'text',:field_name => 'last_name'}
	# column_configs[2] = {:field_type => 'text',:field_name => 'title'}
	# column_configs[3] = {:field_type => 'text',:field_name => 'date_of_birth'}
	# column_configs[4] = {:field_type => 'text',:field_name => 'maiden_name'}
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
