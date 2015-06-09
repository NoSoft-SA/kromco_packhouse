module Tools::ShiftHelper
 
 
 def build_shift_form(shift,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:shift_form]= Hash.new

    search_combos_js = gen_combos_clear_js_for_combos(["shift_shift_type_code", "shift_start_time", "shift_end_time"])

    shift_type_code_observer  = {:updated_field_id => "start_time_cell",
					 :remote_method => 'shift_shift_type_code_changed',
					 :on_completed_js => search_combos_js["shift_shift_type_code"]}

    session[:shift_form][:shift_type_code_observer] = shift_type_code_observer


    #shift_type_codes = Shift.get_all_shift_type_codes
    shift_type_codes = ShiftType.find_by_sql("select shift_type_code from shift_types where shift_type_code <> 'C'").map{|s| [s.shift_type_code] }
    
	  if shift == nil||is_create_retry
	    start_times = ["Select a value from shift_type_code"]
        end_times = ["Select a value from start time"]
	else
		if shift.shift_type_code
          start_times = ShiftType.shift_codes_for_shift_type_code(shift.shift_type_code)
        else
          start_times = ["Select a value from shift type codes"]
        end

        if shift.end_time
          end_times = ShiftType.find_by_sql("select distinct end_time from shift_types where start_time = '#{shift.start_time}' ").map {|s| [s.end_time]}
        else
          end_times = ["Select a value from  start time"]
        end
    end

    line_codes = Shift.find_by_sql('select distinct line_code from lines').map{|s| [s.line_code] }
    line_codes.unshift("<empty>")

    users = User.find_by_sql('select user_name  from users').map{|s| [s.user_name]}
    users.unshift("<empty>")


#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (shift_type_id) on related table: shift_types
#	----------------------------------------------------------------------------------------------
    field_configs = Array.new
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'shift_type_code',
						:settings => {:list => shift_type_codes},
						:observer => shift_type_code_observer}
 
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',:field_name => 'start_time'}


	field_configs[field_configs.length()] =  {:field_type => 'LabelField',:field_name => 'end_time'}
					
 
	field_configs[field_configs.length()] = {:field_type => 'PopupDateSelector',
						:field_name => 'calendar_date',
                        :settings=>{:date_text_field_id=> 'calender_date'}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'line_code',
                        :settings =>{:list => line_codes}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'user',
                        :settings=>{:list => users} }

    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'people_working_on_shift'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'machine_minutes'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'clocked_minutes'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'overtime'}
  field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'people_absent'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'people_off_sick'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'people_on_leave'}
    
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'supervisor'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'sorter'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'packer'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_infeed'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_class2'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_line'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_label'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_rebin'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'forklift'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'palletizer'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'cleaner'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'sample'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'strapper'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'bak_man'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'sakkie_man'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'carton_scanner'}
    
  
    
    
    

	build_form(shift,field_configs,action,'shift',caption,is_edit)

end

  #================================================================================================
  #========> here there is  use of date range

  #===================================== SEARCH FORM================================================
 
 def build_shift_search_form(shift,action,caption,is_flat_search = nil)


   session[:shift_form]= Hash.new

  #  -----------------------------------------
  #  define fields to build drop_down_fields
  #  -----------------------------------------
      line_codes = Shift.find_by_sql('select distinct line_code from shifts').map{|s| s.line_code}
      line_codes.unshift("<empty>")

      users =  User.find_by_sql('select distinct user_name from users').map{|s| s.user_name }
      users.unshift("<empty>")

       shift_types =  ShiftType.find_by_sql('select distinct shift_type_code from shift_types').map{|s| s.shift_type_code }

      shift_type_codes = ShiftType.find_by_sql('select distinct shift_type_code from shift_types').map{|s| s.shift_type_code}
      shift_type_codes.unshift("<empty>")

      field_configs = Array.new

      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                           :field_name => 'user',
                           :settings => {:list => users}}

      field_configs[field_configs.length()] =  {:field_type => 'PopupDateRangeSelector',
                            :field_name => 'start_date_time'}

       field_configs[field_configs.length()] =  {:field_type => 'PopupDateRangeSelector',
                            :field_name => 'end_date_time'}

     field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                           :field_name => 'line_code',
                           :settings => {:list => line_codes}}

      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                           :field_name => 'shift_type_code',
                           :settings => {:list => shift_types}}
   
 
	build_form(shift,field_configs,action,'shift',caption,false)

end



 def build_shift_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'shift_type_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'start_date_time'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'end_date_time'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'calendar_date'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'line_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'user'}

  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'people_working_on_shift'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'machine_minutes'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'clocked_minutes'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'overtime'}
  
  column_configs << {:field_type => 'link_window', :field_name => 'cartons_packed',:settings =>{:link_text=>'cartons_packed',:target_action => 'cartons_packed_report', :id_column => 'id'},:col_width=>75}
  
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'people_absent'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'people_off_sick'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'people_on_leave'}
  
  
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'supervisor'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'sorter'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'packer'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'operator_infeed'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'operator_class2'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'operator_line'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'operator_label'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'operator_rebin'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'forklift'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'palletizer'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'cleaner'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'sample'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'strapper'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'bak_man'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'sakkie_man'}
  column_configs[column_configs.length()] =  {:field_type => 'text',:field_name => 'carton_scanner'}




#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit shift',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_shift',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete shift',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_shift',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
 end



  def build_edit_form_2(shift,action,caption,is_edit = nil,is_create_retry = nil)
    line_codes = Shift.find_by_sql('select distinct line_code from lines').map{|s| [s.line_code] }
    line_codes.unshift("<empty>")

    users = User.find_by_sql('select user_name  from users').map{|s| [s.user_name]}
    users.unshift("<empty>")

    field_configs = Array.new
    field_configs[field_configs.length()] =  {:field_type => 'LabelField',:field_name => 'shift_type_code'}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => 'calendar_date'}
                   
    field_configs[field_configs.length()] =  {:field_type => 'LabelField',:field_name => 'start_time'}
    field_configs[field_configs.length()] =  {:field_type => 'LabelField',:field_name => 'end_time'}
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						                                  :field_name => 'line_code',
                                                          :settings =>{:list => line_codes}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						                                  :field_name => 'user',
                                                          :settings=>{:list => users} }

    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'people_working_on_shift'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'machine_minutes'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'clocked_minutes'}
  
  field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'overtime'}
  field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'people_absent'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'people_off_sick'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'people_on_leave'}
    
    
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'supervisor'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'sorter'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'packer'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_infeed'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_class2'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_line'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_label'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'operator_rebin'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'forklift'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'palletizer'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'cleaner'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'sample'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'strapper'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'bak_man'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'sakkie_man'}
    field_configs[field_configs.length()] =  {:field_type => 'TextField',:field_name => 'carton_scanner'}
    
  
  

    build_form(shift,field_configs,action,'shift',caption,is_edit)
  end



end
