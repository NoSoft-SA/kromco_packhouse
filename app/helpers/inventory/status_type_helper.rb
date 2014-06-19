module Inventory::StatusTypeHelper


 def build_status_type_form(status_type,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:status_type_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs << {:field_type => 'TextField',
						:field_name => 'status_type_code'}

	build_form(status_type,field_configs,action,'status_type',caption,is_edit)

end


 def build_status_type_search_form(status_type,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:status_type_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["status_type_status_type_code"])
	#Observers for search combos

	status_type_codes = StatusType.find_by_sql('select distinct status_type_code from status_types').map{|g|[g.status_type_code]}
	status_type_codes.unshift("<empty>")
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
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'status_type_code',
						:settings => {:list => status_type_codes}}

	build_form(status_type,field_configs,action,'status_type',caption,false)

end



 def build_status_type_grid(data_set,can_delete)

	column_configs = Array.new
	column_configs << {:field_type => 'text',:field_name => 'status_type_code'}
  column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view statuses',
                                                    :settings =>
                                                            {:link_text => 'statuses',
                                                             :target_action => 'list_statuses',
                                                             :id_column => 'id'}}

  	column_configs << {:field_type => 'link_window',:field_name => ' view object status_histories',
			                                              :settings =>
				                                                {:link_text =>'status history',
				                                                  :target_action =>'status_history_popup',
				                                                            :id_column => 'id'}}
  	if can_delete
		column_configs << {:field_type => 'link_window',:field_name => 'delete status type',
			:settings =>
				 {:link_text => 'delete_status_type',
				:target_action => 'delete_status_type',
				:id_column => 'id'}}
    	end
#	----------------------
#	define action columns
#	----------------------

   grid_command =    {:field_type=>'link_window_field',:field_name =>'new_status_type',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'new_status_type',
                       :link_text => "new status type"}}
      return get_data_grid(data_set,column_configs,nil,nil,grid_command)
 end

# status form
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
	field_configs << {:field_type => 'LabelField',:field_name => 'status_type_code',
                    :settings => {:static_value => session[:status_type_code], :show_label => true}}


   valid_statuses = "EMPTY <BR>"

   statuses = Status.find_all_by_status_type_code(session[:status_type_code]).map{|s| s.status_code}
   valid_statuses += statuses.join("<BR>")

   if is_edit
    field_configs << {:field_type => 'LabelField',:field_name => 'status_code'}
    else
   field_configs << {:field_type => 'TextField',:field_name => 'status_code'}
   end


	field_configs << {:field_type => 'TextField',
						:field_name => 'description'}

    field_configs << {:field_type => 'LabelField',:field_name => 'valid_preceded_by_values',
                    :settings => {:static_value => valid_statuses, :show_label => true, :css_class => 'blue_label_field'}}

  field_configs << {:field_type => 'TextArea',:field_name => 'preceded_by',
                                                     :settings =>{
                                                     :cols=> 25,
                                                     :rows=>7}}

	build_form(status,field_configs,action,'status',caption,is_edit)

  end

  # status grid
   def build_status_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
  	if can_edit
		column_configs << {:field_type => 'link_window',:field_name => 'edit status',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_status',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'link_window',:field_name => 'delete status',
			:settings =>
				 {:link_text => 'delete_status',
				:target_action => 'delete_status',
				:id_column => 'id'}}
    	end

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

 return get_data_grid(data_set,column_configs,nil,nil,grid_command)
end

 def build_status_history_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
  column_configs << {:field_type => 'text',:field_name => 'status_type_code'}
	column_configs << {:field_type => 'text',:field_name => 'status_code'}
	column_configs << {:field_type => 'text',:field_name => 'description'}
	column_configs << {:field_type => 'text',:field_name => 'preceded_by'}

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
  return get_data_grid(data_set,column_configs)

  end


  def build_status_history_search_form(status_history,action,caption,is_edit = nil,is_create_retry = nil)
     session[:status_history_form] = Hash.new
     field_configs = Array.new
     field_configs[field_configs.length()] =  {:field_type => 'TextField', :field_name => 'object_id'}
     build_form(@status_history,field_configs,"status_history_submit",'status_history','submit search')
  end

  def build_transaction_statuses(data_set,can_edit,can_delete)

	column_configs = Array.new
  column_configs << {:field_type => 'text',:field_name => 'status_type_code',:col_width=>164}
  column_configs << {:field_type => 'text',:field_name => 'status_code',:col_width=>208}
	column_configs << {:field_type => 'text',:field_name => 'status_id',:col_width=>98}
	column_configs << {:field_type => 'text',:field_name => 'object_id',:col_width=>158}
	column_configs << {:field_type => 'text',:field_name => 'username',:col_width=>135}
  column_configs << {:field_type => 'text',:field_name => 'created_on',:col_width=>144}

#  if can_edit
#		column_configs << {:field_type => 'action',:field_name => 'edit transaction status',
#			:settings =>
#				 {:link_text => 'edit_transaction_status',
#				:target_action => 'edit_status',
#				:id_column => 'id'}}
#	end
#
#	if can_delete
#		column_configs << {:field_type => 'action',:field_name => 'delete status',
#			:settings =>
#				 {:link_text => 'delete',
#				:target_action => 'delete_status',
#				:id_column => 'id'}}
#	end

  return get_data_grid(data_set,column_configs)
  end





end
