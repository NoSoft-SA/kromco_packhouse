module Tools::ShiftTypeHelper
 
 
 def build_shift_type_form(shift_type,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:shift_type_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    shift_types = (0...24).each_with_index {|s| s }.map{|d| d }
	shift_types.unshift("<empty>")

    field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'shift_type_code'}

	field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'start_time',
                        :settings=>{:list => shift_types}}

	field_configs[2] = {:field_type => 'DropDownField',
						:field_name => 'end_time',
                        :settings=>{:list => shift_types}}

	build_form(shift_type,field_configs,action,'shift_type',caption,is_edit)

  end


 
  def build_shift_type_search_form(shift_type,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:shift_type_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["shift_type_shift_type_code","shift_type_start_time"])
	#Observers for search combos
	shift_type_code_observer  = {:updated_field_id => "start_time_cell",
					 :remote_method => 'shift_type_shift_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["shift_type_shift_type_code"]}

	session[:shift_type_search_form][:shift_type_code_observer] = shift_type_code_observer

 
	shift_type_codes = ShiftType.find_by_sql('select distinct shift_type_code from shift_types').map{|g|[g.shift_type_code]}
	shift_type_codes.unshift("<empty>")
	if is_flat_search
		start_times = ShiftType.find_by_sql('select distinct start_time from shift_types').map{|g|[g.start_time]}
		start_times.unshift("<empty>")
		shift_type_code_observer = nil
	else
		 start_times = ["Select a value from shift_type_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'shift_type_code',
						:settings => {:list => shift_type_codes},
						:observer => shift_type_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'start_time',
						:settings => {:list => start_times}}
 
	build_form(shift_type,field_configs,action,'shift_type',caption,false)

 end



 def build_shift_type_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'shift_type_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'start_time'}
	column_configs[2] = {:field_type => 'text',:field_name => 'end_time'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit shift_type',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_shift_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete shift_type',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_shift_type',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
