module Inventory::StatusHelper
 
 
 def build_status_form(status,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:status_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs << {:field_type => 'TextField',
						:field_name => 'status_type_code'}

	field_configs << {:field_type => 'TextField',
						:field_name => 'status_code'}

	field_configs << {:field_type => 'TextField',
						:field_name => 'description'}

	field_configs << {:field_type => 'TextField',
						:field_name => 'preceded_by'}

	build_form(status,field_configs,action,'status',caption,is_edit)

end
 
 
 def build_status_search_form(status,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:status_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	status_codes = Status.find_by_sql('select distinct status_code from statuses').map{|g|[g.status_code]}
	status_codes.unshift("<empty>")
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'status_code',
						:settings => {:list => status_codes}}

	build_form(status,field_configs,action,'status',caption,false)

end



 def build_status_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
  column_configs << {:field_type => 'text',:field_name => 'status_type_code'}
	column_configs << {:field_type => 'text',:field_name => 'status_code'}
	column_configs << {:field_type => 'text',:field_name => 'description'}
	column_configs << {:field_type => 'text',:field_name => 'preceded_by'}
#	----------------------
#	define action columns
#	----------------------
   grid_command =    {:field_type=>'link_window_field',:field_name =>'new_status',
                          :settings =>
                         {
                          :host_and_port =>request.host_with_port.to_s,
                          :controller =>request.path_parameters['controller'].to_s ,
                          :target_action => 'new_status',
                          :link_text => "new status"}}



	if can_edit
		column_configs << {:field_type => 'action',:field_name => 'edit status',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_status',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete status',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_status',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs,nil,nil,grid_command)
end

end
