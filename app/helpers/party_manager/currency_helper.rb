module PartyManager::CurrencyHelper
 
 
 def build_currency_form(currency,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:currency_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = []
	field_configs << {:field_type => 'TextField',
						:field_name => 'currency_code'}

	field_configs << {:field_type => 'TextField',
						:field_name => 'medium_description'}

	build_form(currency,field_configs,action,'currency',caption,is_edit)

end
 
 
 def build_currency_search_form(currency,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:currency_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = []
	currency_codes = Currency.find_by_sql('select distinct currency_code from currencies').map{|g|[g.currency_code]}
	currency_codes.unshift("<empty>")
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'currency_code',
						:settings => {:list => currency_codes}}

	build_form(currency,field_configs,action,'currency',caption,false)

end



 def build_currency_grid(data_set,can_edit,can_delete)

	column_configs = []
	column_configs << {:field_type => 'text',:field_name => 'currency_code'}
	column_configs << {:field_type => 'text',:field_name => 'medium_description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs << {:field_type => 'action',:field_name => 'edit currency',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_currency',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete currency',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_currency',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
