module Reports::PrinterHelper
 
 
 def build_printer_form(printer,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:printer_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'system_name'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'friendly_name'}

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'ip'}

	build_form(printer,field_configs,action,'printer',caption,is_edit)

end
 
 
 def build_printer_search_form(printer,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:printer_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	system_names = Printer.find_by_sql('select distinct system_name from printers').map{|g|[g.system_name]}
	system_names.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'system_name',
						:settings => {:list => system_names}}

	build_form(printer,field_configs,action,'printer',caption,false)

end



 def build_printer_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'system_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'friendly_name'}
	column_configs[2] = {:field_type => 'text',:field_name => 'ip'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit printer',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_printer',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete printer',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_printer',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
