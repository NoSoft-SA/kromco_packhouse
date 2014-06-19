module Production::DowntimeCategoryHelper
 
 
 def build_downtime_category_form(downtime_category,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:downtime_category_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'downtime_category_code'}

	build_form(downtime_category,field_configs,action,'downtime_category',caption,is_edit)

end
 
 
 def build_downtime_category_search_form(downtime_category,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:downtime_category_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["downtime_category_downtime_category_code"])
	#Observers for search combos
 
	downtime_category_codes = DowntimeCategory.find_by_sql('select distinct downtime_category_code from downtime_categories').map{|g|[g.downtime_category_code]}
	downtime_category_codes.unshift("<empty>")
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
						:field_name => 'downtime_category_code',
						:settings => {:list => downtime_category_codes}}
 
	build_form(downtime_category,field_configs,action,'downtime_category',caption,false)

end



 def build_downtime_category_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'downtime_category_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit downtime_category',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_downtime_category',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete downtime_category',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_downtime_category',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
