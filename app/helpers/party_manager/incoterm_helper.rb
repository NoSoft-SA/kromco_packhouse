module PartyManager::IncotermHelper
 
 
 def build_incoterm_form(incoterm,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:incoterm_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = []
	field_configs << {:field_type => 'TextField',
						:field_name => 'incoterm_code'}

	field_configs << {:field_type => 'TextField',
						:field_name => 'medium_description'}

	build_form(incoterm,field_configs,action,'incoterm',caption,is_edit)

end
 
 
 def build_incoterm_search_form(incoterm,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:incoterm_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = []
	incoterm_codes = Incoterm.find_by_sql('select distinct incoterm_code from incoterms').map{|g|[g.incoterm_code]}
	incoterm_codes.unshift("<empty>")
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'incoterm_code',
						:settings => {:list => incoterm_codes}}

	build_form(incoterm,field_configs,action,'incoterm',caption,false)

end



 def build_incoterm_grid(data_set,can_edit,can_delete)

	column_configs = []
	column_configs << {:field_type => 'text',:field_name => 'incoterm_code'}
	column_configs << {:field_type => 'text',:field_name => 'medium_description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs << {:field_type => 'action',:field_name => 'edit incoterm',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_incoterm',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete incoterm',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_incoterm',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
