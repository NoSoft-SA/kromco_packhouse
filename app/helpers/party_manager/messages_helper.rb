

module PartyManager::MessagesHelper
	
  
  def build_message_form(message,action,field_name,is_department_form = nil)
  	
  	field_configs = Array.new
  	
  	departments = Department.find(:all).map{|d|[d.department_name]}
  	departments.unshift("<empty>")
  	
  	if is_department_form
  	  on_complete_js = "\n img = document.getElementById('img_message_department');"
	  on_complete_js += "\n if(img != null)img.style.display = 'none';"
	
  	  dept_observer  = {:updated_field_id => "message_body_cell",
					 :remote_method => 'department_changed',
					 :on_completed_js => on_complete_js}
					 
  	  field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'department',
						:settings => {:list => departments},
						:observer => dept_observer}
						
  	end
  	
  	field_configs[field_configs.length()] = {:field_type => 'TextArea',
  	                    :field_name => field_name,
  	                    :settings => {:cols => 40,:rows => 10}}
  
  	build_form(message,field_configs,action,'message','save')
  	
  end


  def get_users_grid(data_set)
  	
  	column_configs = Array.new
  	
  	column_configs[0]= {:field_type => "text",:field_name => "user_name"}
	column_configs[1] = {:field_type => 'text',:field_name => 'department_name'}
	column_configs[2] = {:field_type => 'text',:field_name => 'last_name'}
	column_configs[3] = {:field_type => 'text',:field_name => 'first_name'}
  	
  	column_configs[4]= {:field_type => "action",:field_name => "set message",
  								   :settings => 
  								   		{:image => "set_message",
  								   		 :target_action => "set_user_message",
  								   	     :id_column => "id"} }
  	
  	return get_data_grid(data_set,column_configs)
  	
  end
 

  def build_user_search_form(user,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:user_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["user_department_name","user_last_name","user_first_name","user_user_name"])
	#Observers for search combos
	department_name_observer  = {:updated_field_id => "last_name_cell",
					 :remote_method => 'user_department_name_search_combo_changed',
					 :on_completed_js => search_combos_js["user_department_name"]}

	session[:user_search_form][:department_name_observer] = department_name_observer

	last_name_observer  = {:updated_field_id => "first_name_cell",
					 :remote_method => 'user_last_name_search_combo_changed',
					 :on_completed_js => search_combos_js["user_last_name"]}

	session[:user_search_form][:last_name_observer] = last_name_observer

	first_name_observer  = {:updated_field_id => "user_name_cell",
					 :remote_method => 'user_first_name_search_combo_changed',
					 :on_completed_js => search_combos_js["user_first_name"]}

	session[:user_search_form][:first_name_observer] = first_name_observer

 
	department_names = User.find_by_sql('select distinct department_name from users').map{|g|[g.department_name]}
	department_names.unshift("<empty>")
	if is_flat_search
		last_names = User.find_by_sql('select distinct last_name from users').map{|g|[g.last_name]}
		last_names.unshift("<empty>")
		first_names = User.find_by_sql('select distinct first_name from users').map{|g|[g.first_name]}
		first_names.unshift("<empty>")
		user_names = User.find_by_sql('select distinct user_name from users').map{|g|[g.user_name]}
		user_names.unshift("<empty>")
		department_name_observer = nil
		last_name_observer = nil
		first_name_observer = nil
	else
		 last_names = ["Select a value from department_name"]
		 first_names = ["Select a value from last_name"]
		 user_names = ["Select a value from first_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'department_name',
						:settings => {:list => department_names},
						:observer => department_name_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'last_name',
						:settings => {:list => last_names},
						:observer => last_name_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'first_name',
						:settings => {:list => first_names},
						:observer => first_name_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'user_name',
						:settings => {:list => user_names}}
 
	build_form(user,field_configs,action,'user',caption,false)

end



 
  
	
end

