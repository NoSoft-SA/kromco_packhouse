module QualityControl::PpecbReasonHelper
 
 
 def build_ppecb_reason_form(ppecb_reason,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:ppecb_reason_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'reason_description'}

	build_form(ppecb_reason,field_configs,action,'ppecb_reason',caption,is_edit)

end
 
 
 def build_ppecb_reason_search_form(ppecb_reason,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:ppecb_reason_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	reason_descriptions = PpecbReason.find_by_sql('select distinct reason_description from ppecb_reasons').map{|g|[g.reason_description]}
	reason_descriptions.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'reason_description',
						:settings => {:list => reason_descriptions}}

	build_form(ppecb_reason,field_configs,action,'ppecb_reason',caption,false)

end



 def build_ppecb_reason_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'reason_description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit ppecb_reason',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_ppecb_reason',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete ppecb_reason',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_ppecb_reason',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
