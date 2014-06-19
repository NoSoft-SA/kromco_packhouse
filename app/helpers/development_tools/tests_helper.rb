module DevelopmentTools::TestsHelper
 
  def build_test_function_form(func_area_names)

	session[:test_program_form]= Hash.new
	
	combos_js = gen_combos_clear_js_for_combos(["prog_functional_area","prog_program","prog_function"])
	#Observers for combos representing the key fields of fkey table: golfer_status_id
	func_area_observer  = {:updated_field_id => "program_cell",
					 :remote_method => 'prog_functional_area_changed_f',
					 :on_completed_js => combos_js ["prog_functional_area"]}

	session[:test_program_form][:func_area_observer] = func_area_observer

	prog_observer  = {:updated_field_id => "function_cell",
					 :remote_method => 'prog_program_changed_f',
					 :on_completed_js => combos_js["prog_program"]}

	session[:test_program_form][:prog_observer] = prog_observer

	
	progs = ["Select a functional area"]
	functions = ["Select a program"]
	
	field_configs = Array.new
	
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area',
						:settings => {:list => func_area_names},
						:observer => func_area_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'program',
						:settings => {:list => progs}}
  
    field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'function',
						:settings => {:list => functions}}
 
	build_form(nil,field_configs,"test_function_submit",'prog',"run")

end
 
 def build_test_program_form(func_area_names)

	session[:test_program_form]= Hash.new
	
	combos_js = gen_combos_clear_js_for_combos(["prog_functional_area","prog_program"])
	#Observers for combos representing the key fields of fkey table: golfer_status_id
	func_area_observer  = {:updated_field_id => "program_cell",
					 :remote_method => 'prog_functional_area_changed',
					 :on_completed_js => combos_js ["prog_functional_area"]}

	session[:test_program_form][:func_area_observer] = func_area_observer

	#club_observer  = {:updated_field_id => "status_cell",
	#				 :remote_method => 'golfer_club_changed',
	#				 :on_completed_js => combos_js_for_golfer_statuses ["golfer_club"]}

	#session[:golfer_form][:club_observer] = club_observer

#	combo lists for table: golfer_statuses 
 
	
	progs = ["Select a functional area"]
	
	field_configs = Array.new
	
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area',
						:settings => {:list => func_area_names},
						:observer => func_area_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'program',
						:settings => {:list => progs}}
 
 
	build_form(nil,field_configs,"test_program_submit",'prog',"run")

end
 


end
