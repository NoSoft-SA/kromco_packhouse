module ChangeControl::IssueHelper
 
 
 def build_issue_form(issue,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:issue_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: subsystems
	combos_js_for_subsystems = gen_combos_clear_js_for_combos(["issue_system_name","issue_subsystem_name"])
	combos_js_for_tickets = gen_combos_clear_js_for_combos(["issue_project_name","issue_ticket_name"])
	combos_js_for_affected_objects = gen_combos_clear_js_for_combos(["issue_system_name","issue_subsystem_name","issue_affected_object_type_name","issue_affected_object_name"])
	#Observers for combos representing the key fields of fkey table: subsystem_id
	#generate javascript for the on_complete ajax event for each combo for fk table: tickets
	combos_js_for_subsystems = gen_combos_clear_js_for_combos(["issue_system_name","issue_subsystem_name"])
	combos_js_for_tickets = gen_combos_clear_js_for_combos(["issue_project_name","issue_ticket_name"])
	combos_js_for_affected_objects = gen_combos_clear_js_for_combos(["issue_system_name","issue_subsystem_name","issue_affected_object_type_name","issue_affected_object_name"])
	#Observers for combos representing the key fields of fkey table: ticket_id
	#generate javascript for the on_complete ajax event for each combo for fk table: affected_objects
	combos_js_for_subsystems = gen_combos_clear_js_for_combos(["issue_system_name","issue_subsystem_name"])
	combos_js_for_tickets = gen_combos_clear_js_for_combos(["issue_project_name","issue_ticket_name"])
	combos_js_for_affected_objects = gen_combos_clear_js_for_combos(["issue_system_name","issue_subsystem_name","issue_affected_object_type_name","issue_affected_object_name"])
	#Observers for combos representing the key fields of fkey table: affected_object_id
	system_name_observer  = {:updated_field_id => "subsystem_name_cell",
					 :remote_method => 'issue_system_name_changed',
					 :on_completed_js => combos_js_for_subsystems ["issue_system_name"]}

	session[:issue_form][:system_name_observer] = system_name_observer

#	combo lists for table: subsystems

	system_names = nil 
	subsystem_names = nil 
 
	system_names = Issue.get_all_system_names
	if issue == nil||is_create_retry
		 subsystem_names = ["Select a value from system_name"]
	else
	   puts "IID: " + issue.subsystem_id.to_s
		subsystem_names = Issue.subsystem_names_for_system_name(issue.subsystem.system_name)
	end
	project_name_observer  = {:updated_field_id => "ticket_name_cell",
					 :remote_method => 'issue_project_name_changed',
					 :on_completed_js => combos_js_for_tickets ["issue_project_name"]}

	session[:issue_form][:project_name_observer] = project_name_observer

#	combo lists for table: tickets
  
	project_names = nil 
	ticket_names = nil 
 
	project_names = Issue.get_all_project_names
	project_names.unshift("<empty>")
	 
	if issue == nil||is_create_retry
		 ticket_names = ["Select a value from project_name"]
	else
		ticket_names = Issue.ticket_names_for_project_name(issue.ticket.project_name)
	end
	system_name_observer  = {:updated_field_id => "subsystem_name_cell",
					 :remote_method => 'issue_system_name_changed',
					 :on_completed_js => combos_js_for_affected_objects ["issue_system_name"]}

	session[:issue_form][:system_name_observer] = system_name_observer

	subsystem_name_observer  = {:updated_field_id => "affected_object_type_name_cell",
					 :remote_method => 'issue_subsystem_name_changed',
					 :on_completed_js => combos_js_for_affected_objects ["issue_subsystem_name"]}

	session[:issue_form][:subsystem_name_observer] = subsystem_name_observer

	affected_object_type_name_observer  = {:updated_field_id => "affected_object_name_cell",
					 :remote_method => 'issue_affected_object_type_name_changed',
					 :on_completed_js => combos_js_for_affected_objects ["issue_affected_object_type_name"]}

	session[:issue_form][:affected_object_type_name_observer] = affected_object_type_name_observer

#	combo lists for table: affected_objects

	system_names = nil 
	subsystem_names = nil 
	affected_object_type_names = nil 
	affected_object_names = nil 
 
	system_names = Issue.get_all_system_names
	if issue == nil||is_create_retry
		 subsystem_names = ["Select a value from system_name"]
		 affected_object_type_names = ["Select a value from subsystem_name"]
		 affected_object_names = ["Select a value from affected_object_type_name"]
	else
		subsystem_names = Issue.subsystem_names_for_system_name(issue.affected_object.system_name)
		affected_object_type_names = Issue.affected_object_type_names_for_subsystem_name_and_system_name(issue.affected_object.subsystem_name, issue.affected_object.system_name)
		affected_object_names = Issue.affected_object_names_for_affected_object_type_name_and_subsystem_name_and_system_name(issue.affected_object.affected_object_type_name, issue.affected_object.subsystem_name, issue.affected_object.system_name)
	end
	
	 system_names.unshift("<empty>")
    functional_area_names = FunctionalArea.find_all().map{|f|[f.functional_area_name]}
    user_names = Person.all_it_staff
    request_user_names = Person.allEmployees_as_text
	statuses = ["opened","assigned","in work","rejected","paused","completed","extension","test-rework","listed"]
	issue_types = ["research","analyses","documentation","system testing","user testing","design","specification","UI design","coding","testing_rework","patch","extension","deployment","unit_testing"]
    severities = ["n.a.","non critical","critical","medium"]
    
     #	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	 
	  issue = Issue.new if !issue
	  issue.affected_resources = "n.a." if !issue.affected_resources
	 
	 #----------------------------------------------------------------------------------------------
#	 Combo fields to represent foreign key (ticket_id) on related table: tickets
#	----------------------------------------------------------------------------------------------
	if !is_edit
	    
	    
	    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'project_name?required',
						:settings => {:list => project_names},
						:observer => project_name_observer}
 
	   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'ticket_name?required',
						:settings => {:list => ticket_names}}
						
	   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'issue_type?required',
						:settings => {:list => issue_types}}
		
					
	  #	----------------------------------------------------------------------------------------------
          #	Combo fields to represent foreign key (affected_object_id) on related table: affected_objects
          #	----------------------------------------------------------------------------------------------
	  field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
							:field_name => 'system_name?required',
							:settings => {:list => system_names},
							:observer => system_name_observer}
	 
          field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
							:field_name => 'subsystem_name?required',
							:settings => {:list => subsystem_names},
							:observer => subsystem_name_observer}
	 
          field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
							:field_name => 'affected_object_type_name?required',
							:settings => {:list => affected_object_type_names},
							:observer => affected_object_type_name_observer}
	 
	  field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
							:field_name => 'affected_object_name?required',
						:settings => {:list => affected_object_names}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name?required',
						:settings => {:list => functional_area_names}}
						
						
	else
	  
	  field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'id'}
	
	  field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'project_name'}
						
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'ticket_name'}
	
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'issue_type'}
						
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'system_name'}
						
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'subsystem_name'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'affected_object_type_name'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'functional_area_name'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'affected_object_name'}
						
										
	end
	
	field_configs[field_configs.length()] =  {:field_type => 'PopupDateSelector',
	                     :field_name => 'created_date',
	                     :settings => {:date_textfield_id=>'created_date'}}
	
	field_configs[field_configs.length()] =  {:field_type => 'PopupDateSelector',
	                     :field_name => 'required_date',
	                     :settings => {:date_textfield_id=>'required_date'}}

   field_configs[field_configs.length()] =  {:field_type => 'PopupDateSelector',
	                     :field_name => 'estimated_complete_date',
	                     :settings => {:date_textfield_id=>'estimated_complete_date'}}
	                     
   
	                     
	field_configs[field_configs.length()] =  {:field_type => 'PopupDateSelector',
	                     :field_name => 'actual_complete_date',
	                     :settings => {:date_textfield_id=>'actual_complete_date'}}
	                     
	 field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'priority'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'logged_by'}

	field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'description?required',
						:settings => {:cols => 60,:rows => 10}}
						
						
	field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'affected_resources?required',
						:settings => {:cols => 60,:rows => 10}}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'created_at'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'completed_at'}

	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'status?required',
						:settings => {:list => statuses,:label_css_class => "blue_label_field"}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'requested_by?required',
						:settings => {:list => request_user_names}}

	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'assigned_to?required',
						:settings => {:list => user_names}}

	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'severity?required',
						:settings => {:list => severities}}


 
	field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'remarks',
						:settings => {:cols => 60,:rows => 10}}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'estimated_effort?required'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'actual_effort'}


	field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'documents',
						:settings => {:cols => 60,:rows => 10}}
						
	
    field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'view tracks',
                       :settings =>
                      {:id_column => "id",
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'view_tracks',
                       :link_text => 'view tracks'}} if issue && issue.id
                       
      field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'view todos',
                       :settings =>
                      {:id_column => "id",
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'view_todos',
                       :link_text => 'view todos'}} if issue && issue.id
                       
        field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'new todo',
                       :settings =>
                      {:id_column => "id",
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'new_todo',
                       :link_text => 'new todo'}} if issue && issue.id
    
 
	build_form(issue,field_configs,action,'issue',caption,is_edit)

end

 
 def build_todos_grid(data_set)
   
   require File.dirname(__FILE__) + "/../../../app/helpers/change_control/issue_plugin.rb"
    
	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'description'}
	column_configs[1] = {:field_type => 'text',:field_name => 'complete_by'}
	column_configs[2] = {:field_type => 'text',:field_name => 'completed'}

	
	column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'edit todo',
			:settings => 
				 {:link_text => 'edit todo',
				 :host_and_port =>request.host_with_port.to_s,
				 :controller =>request.path_parameters['controller'].to_s ,
				 :target_action => 'edit_todo',
				 :id_column => 'id'}}
				 
				 
	column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'delete todo',
			:settings => 
				 {:link_text => 'delete todo',
				 :host_and_port =>request.host_with_port.to_s,
				 :controller =>request.path_parameters['controller'].to_s ,
				 :target_action => 'delete_todo',
				 :id_column => 'id'}}
				
				
 return get_data_grid(data_set,column_configs,IssuePlugins::TodoGridPlugin.new)
 
 
 end
 
 
 def build_todo_form(todo,action,caption,is_edit = nil)
   
    field_configs = Array.new
	 
						
	field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'description?required',
						:settings => {:cols => 60,:rows => 10}}
						
	field_configs[field_configs.length()] =  {:field_type => 'PopupDateSelector',
	                     :field_name => 'complete_by',
	                     :settings => {:date_textfield_id=>'complete_by'}}
						
	field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'completed'}
						
															

	build_form(todo,field_configs,action,'todo',caption,is_edit)
   
 end
 
 def view_issue_track(issue_track)
 
   field_configs = Array.new
   
   field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'description'}
						
   field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'created_on'}
						
	
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'created_date'}
						
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'required_date'}
						
						
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'actual_complete_date'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'severity'}
																
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'severity'}
						
   field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'status'}
						
   field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'assigned_to'}
						
  field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'severity'}
						
  field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'remarks'}
						
  field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'estimated_effort'}
						
  field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'actual_effort'}
						
  field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'issue_type'}
						
  field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'ticket_name'}
						
  field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'project_name'}	
	
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'affected_resources'}
						
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'requested_by'}							
						
	build_form(issue_track,field_configs,nil,'issue_track','')				
 
 
 end
 
 def build_tracks_grid(data_set)
  
  column_configs = Array.new
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'description'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'created_on'}
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'status'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'assigned_to'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'severity'}
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'remarks'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'estimated_effort'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'actual_effort'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'issue_type'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'ticket_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'project_name'}
   
   column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'view track',
			:settings => 
				 {:link_text => 'view form',
				 :host_and_port =>request.host_with_port.to_s,
				 :controller =>request.path_parameters['controller'].to_s ,
				 :target_action => 'view_track',
				 :id_column => 'id'}}
				 
   
    return get_data_grid(data_set,column_configs)
 
 end
 
 def build_tracks_grid(data_set)
  
  column_configs = Array.new
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'description'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'created_on'}
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'status'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'assigned_to'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'severity'}
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'remarks'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'estimated_effort'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'actual_effort'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'issue_type'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'ticket_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'project_name'}
   
   column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'view track',
			:settings => 
				 {:link_text => 'view form',
				 :host_and_port =>request.host_with_port.to_s,
				 :controller =>request.path_parameters['controller'].to_s ,
				 :target_action => 'view_track',
				 :id_column => 'id'}}
				 
   
    return get_data_grid(data_set,column_configs)
 
 end
 
def build_issue_search_form(issue,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:issue_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["issue_project_name","issue_ticket_name","issue_issue_type","issue_status","issue_system_name","issue_subsystem_name","issue_affected_object_type_name","issue_affected_object_name","issue_assigned_to"])
	#Observers for search combos
	project_name_observer  = {:updated_field_id => "ticket_name_cell",
					 :remote_method => 'issue_project_name_search_combo_changed',
					 :on_completed_js => search_combos_js["issue_project_name"]}

	session[:issue_search_form][:project_name_observer] = project_name_observer

	ticket_name_observer  = {:updated_field_id => "issue_type_cell",
					 :remote_method => 'issue_ticket_name_search_combo_changed',
					 :on_completed_js => search_combos_js["issue_ticket_name"]}

	session[:issue_search_form][:ticket_name_observer] = ticket_name_observer

	issue_type_observer  = {:updated_field_id => "status_cell",
					 :remote_method => 'issue_issue_type_search_combo_changed',
					 :on_completed_js => search_combos_js["issue_issue_type"]}

	session[:issue_search_form][:issue_type_observer] = issue_type_observer

	status_observer  = {:updated_field_id => "system_name_cell",
					 :remote_method => 'issue_status_search_combo_changed',
					 :on_completed_js => search_combos_js["issue_status"]}

	session[:issue_search_form][:status_observer] = status_observer

	system_name_observer  = {:updated_field_id => "subsystem_name_cell",
					 :remote_method => 'issue_system_name_search_combo_changed',
					 :on_completed_js => search_combos_js["issue_system_name"]}

	session[:issue_search_form][:system_name_observer] = system_name_observer

	subsystem_name_observer  = {:updated_field_id => "affected_object_type_name_cell",
					 :remote_method => 'issue_subsystem_name_search_combo_changed',
					 :on_completed_js => search_combos_js["issue_subsystem_name"]}

	session[:issue_search_form][:subsystem_name_observer] = subsystem_name_observer

	affected_object_type_name_observer  = {:updated_field_id => "affected_object_name_cell",
					 :remote_method => 'issue_affected_object_type_name_search_combo_changed',
					 :on_completed_js => search_combos_js["issue_affected_object_type_name"]}

	session[:issue_search_form][:affected_object_type_name_observer] = affected_object_type_name_observer

	affected_object_name_observer  = {:updated_field_id => "assigned_to_cell",
					 :remote_method => 'issue_affected_object_name_search_combo_changed',
					 :on_completed_js => search_combos_js["issue_affected_object_name"]}

	session[:issue_search_form][:affected_object_name_observer] = affected_object_name_observer

 
	project_names = Issue.find_by_sql('select distinct project_name from issues').map{|g|[g.project_name]}
	project_names.unshift("<empty>")
	if is_flat_search
		ticket_names = Issue.find_by_sql('select distinct ticket_name from issues').map{|g|[g.ticket_name]}
		ticket_names.unshift("<empty>")
		issue_types = Issue.find_by_sql('select distinct issue_type from issues').map{|g|[g.issue_type]}
		issue_types.unshift("<empty>")
		statuses = Issue.find_by_sql('select distinct status from issues').map{|g|[g.status]}
		statuses.unshift("<empty>")
		system_names = Issue.find_by_sql('select distinct system_name from issues').map{|g|[g.system_name]}
		system_names.unshift("<empty>")
		subsystem_names = Issue.find_by_sql('select distinct subsystem_name from issues').map{|g|[g.subsystem_name]}
		subsystem_names.unshift("<empty>")
		affected_object_type_names = Issue.find_by_sql('select distinct affected_object_type_name from issues').map{|g|[g.affected_object_type_name]}
		affected_object_type_names.unshift("<empty>")
		affected_object_names = Issue.find_by_sql('select distinct affected_object_name from issues').map{|g|[g.affected_object_name]}
		affected_object_names.unshift("<empty>")
		assigned_tos = Issue.find_by_sql('select distinct assigned_to from issues').map{|g|[g.assigned_to]}
		assigned_tos.unshift("<empty>")
		project_name_observer = nil
		ticket_name_observer = nil
		issue_type_observer = nil
		status_observer = nil
		system_name_observer = nil
		subsystem_name_observer = nil
		affected_object_type_name_observer = nil
		affected_object_name_observer = nil
	else
		 ticket_names = ["Select a value from project_name"]
		 issue_types = ["Select a value from ticket_name"]
		 statuses = ["Select a value from issue_type"]
		 system_names = ["Select a value from status"]
		 subsystem_names = ["Select a value from system_name"]
		 affected_object_type_names = ["Select a value from subsystem_name"]
		 affected_object_names = ["Select a value from affected_object_type_name"]
		 assigned_tos = ["Select a value from affected_object_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'project_name',
						:settings => {:list => project_names},
						:observer => project_name_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'ticket_name',
						:settings => {:list => ticket_names},
						:observer => ticket_name_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'issue_type',
						:settings => {:list => issue_types},
						:observer => issue_type_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'status',
						:settings => {:list => statuses},
						:observer => status_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'system_name',
						:settings => {:list => system_names},
						:observer => system_name_observer}
 
	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'subsystem_name',
						:settings => {:list => subsystem_names},
						:observer => subsystem_name_observer}
 
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'affected_object_type_name',
						:settings => {:list => affected_object_type_names},
						:observer => affected_object_type_name_observer}
 
	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'affected_object_name',
						:settings => {:list => affected_object_names},
						:observer => affected_object_name_observer}
 
	field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'assigned_to',
						:settings => {:list => assigned_tos}}
 
	build_form(issue,field_configs,action,'issue',caption,false)

end



 def build_issue_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	
	 require File.dirname(__FILE__) + "/../../../app/helpers/change_control/issue_plugin.rb"
	 
	 
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'description'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'created_at'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'completed_at'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'status'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'assigned_to'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'affected_object_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'affected_object_type_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'system_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'subsystem_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'functional_area_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'remarks'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'estimated_effort'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'actual_effort'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'issue_type'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'documents'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'ticket_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'project_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'ticket_status'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'severity'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'estimated_complete_date'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'actual_complete_date'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit issue',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_issue',
				:id_column => 'id'}}
				
				
	 column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'clone issue',
			:settings => 
				 {:link_text => 'clone',
				:target_action => 'clone_issue',
				:id_column => 'id'}}
	end
	

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete issue',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_issue',
				:id_column => 'id'},:html_options => {:prompt => "Are you sure you want to do delete this issue?"}}
	end
	
	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'issue track',
			:settings => 
				 {:link_text => 'issue track',
				:target_action => 'view_tracks',
				:id_column => 'id'}}
	
		
				
 return get_data_grid(data_set,column_configs,IssuePlugins::IssuePlugin.new)
end

end
