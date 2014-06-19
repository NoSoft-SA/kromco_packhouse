module ChangeControl::TicketHelper
 
 
 def build_ticket_form(ticket,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:ticket_form]= Hash.new
	project_names = Project.find_by_sql('select distinct project_name from projects').map{|g|[g.project_name]}
	project_names.unshift("<empty>")
	
	
	
	
	statuses = ["opened","assigned","in work","rejected","paused","completed"]
	ticket_types = ["bug fix","change request","new software","research","scoping","analyses"]
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	 
	 field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'project_name',
						:settings => {:list => project_names}}
						
	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'ticket_name'}
						
	 field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'status',
						:settings => {:list => statuses}}
						
						
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'ticket_type',
						:settings => {:list => ticket_types}}
						
	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'description'}
						
						
	field_configs[5] = {:field_type => 'TextField',
						:field_name => 'reference'}															

	build_form(ticket,field_configs,action,'ticket',caption,is_edit)

end
 
 
 def build_ticket_search_form(ticket,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:ticket_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["ticket_project_name","ticket_ticket_name","ticket_status"])
	#Observers for search combos
	project_name_observer  = {:updated_field_id => "ticket_name_cell",
					 :remote_method => 'ticket_project_name_search_combo_changed',
					 :on_completed_js => search_combos_js["ticket_project_name"]}

	session[:ticket_search_form][:project_name_observer] = project_name_observer

	ticket_name_observer  = {:updated_field_id => "status_cell",
					 :remote_method => 'ticket_ticket_name_search_combo_changed',
					 :on_completed_js => search_combos_js["ticket_ticket_name"]}

	session[:ticket_search_form][:ticket_name_observer] = ticket_name_observer

 
	project_names = Ticket.find_by_sql('select distinct project_name from tickets').map{|g|[g.project_name]}
	project_names.unshift("<empty>")
	
	references = Ticket.find_by_sql('select distinct reference from tickets').map{|g|[g.reference]}
	references.unshift("<empty>")
	
	
	if is_flat_search
		ticket_names = Ticket.find_by_sql('select distinct ticket_name from tickets').map{|g|[g.ticket_name]}
		ticket_names.unshift("<empty>")
		statuses = Ticket.find_by_sql('select distinct status from tickets').map{|g|[g.status]}
		statuses.unshift("<empty>")
		project_name_observer = nil
		ticket_name_observer = nil
	else
		 ticket_names = ["Select a value from project_name"]
		 statuses = ["Select a value from ticket_name"]
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
						:field_name => 'status',
						:settings => {:list => statuses}}
						
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'reference',
						:settings => {:list => references}}
 
	build_form(ticket,field_configs,action,'ticket',caption,false)

end



 def build_ticket_grid(data_set,can_edit,can_delete)

    require File.dirname(__FILE__) + "/../../../app/helpers/change_control/issue_plugin.rb"
    
	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'ticket_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'project_name'}
	column_configs[2] = {:field_type => 'text',:field_name => 'status'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit ticket',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_ticket',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete ticket',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_ticket',
				:id_column => 'id'}}
	end
	
	column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'view tasks',
			:settings => 
				 {:link_text => 'view tasks',
				 :host_and_port =>request.host_with_port.to_s,
				 :controller =>request.path_parameters['controller'].to_s ,
				 :target_action => 'view_tasks',
				 :id_column => 'id'}}
				
				
 return get_data_grid(data_set,column_configs,IssuePlugins::IssuePlugin.new)
end

end
