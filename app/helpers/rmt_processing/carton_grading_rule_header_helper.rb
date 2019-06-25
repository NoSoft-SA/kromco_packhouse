module RmtProcessing::CartonGradingRuleHeaderHelper


 def build_carton_grading_rule_header_form(carton_grading_rule_header,action,caption,is_edit = nil,is_create_retry = nil)
#  --------------------------------------------------------------------------------------------------
#  Define a set of observers for each composite foreign key- in effect an observer per combo involved
#  in a composite foreign key
#  --------------------------------------------------------------------------------------------------
  session[:carton_grading_rule_header_form]= Hash.new
#  ---------------------------------
#   Define fields to build form from
#  ---------------------------------
   field_configs = []
  field_configs << {:field_type => 'PopupDateTimeSelector ',
            :field_name => 'created_by'}

  field_configs << {:field_type => 'PopupDateTimeSelector ',
            :field_name => 'updated_by'}

  field_configs << {:field_type => 'TextField',
            :field_name => 'description'}

  field_configs << {:field_type => 'PopupDateTimeSelector ',
            :field_name => 'deactivated_at'}

  field_configs << {:field_type => 'PopupDateTimeSelector ',
            :field_name => 'activated_at'}

  field_configs << {:field_type => 'TextField',
            :field_name => 'season'}

  construct_form(carton_grading_rule_header,field_configs,action,'carton_grading_rule_header',caption,is_edit)

end


 def build_carton_grading_rule_header_search_form(carton_grading_rule_header,action,caption,is_flat_search = nil)
#  --------------------------------------------------------------------------------------------------
#  Define an observer for each index field
#  --------------------------------------------------------------------------------------------------
  session[:carton_grading_rule_header_search_form]= Hash.new
  #generate javascript for the on_complete ajax event for each combo
  #Observers for search combos
#  ----------------------------------------
#   Define search fields to build form from
#  ----------------------------------------
field_configs = []
  created_ats = CartonGradingRuleHeader.find_by_sql('select distinct created_at from carton_grading_rule_headers').map{|g|[g.created_at]}
  field_configs << {:field_type => 'DropDownField',
            :field_name => 'created_at',
            :settings => {:list => created_ats}}

  construct_form(carton_grading_rule_header,field_configs,action,'carton_grading_rule_header',caption,false)

end



 def build_carton_grading_rule_header_grid(data_set,can_edit,can_delete)

  column_configs = []
  action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
  if can_edit
    action_configs << {:field_type => 'action',:field_name => 'edit carton_grading_rule_header',
      :column_caption => 'Edit',
      :settings =>
         {:link_text => 'edit',
        :link_icon => 'edit',
        :target_action => 'edit_carton_grading_rule_header',
        :id_column => 'id'}}
  end

  if can_delete
    action_configs << {:field_type => 'action',:field_name => 'delete carton_grading_rule_header',
      :column_caption => 'Delete',
      :settings =>
         {:link_text => 'delete',
        :link_icon => 'delete',
        :target_action => 'delete_carton_grading_rule_header',
        :id_column => 'id'}}
  end

  #action_configs << {:field_type => 'separator'} if can_edit || can_delete

  column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

  column_configs << {:field_type => 'text', :field_name => 'created_by', :data_type => 'date', :column_caption => 'Created by'}
  column_configs << {:field_type => 'text', :field_name => 'updated_by', :data_type => 'date', :column_caption => 'Updated by'}
  column_configs << {:field_type => 'text', :field_name => 'description', :column_caption => 'Description'}
  column_configs << {:field_type => 'text', :field_name => 'deactivated_at', :data_type => 'date', :column_caption => 'Deactivated at'}
  column_configs << {:field_type => 'text', :field_name => 'activated_at', :data_type => 'date', :column_caption => 'Activated at'}
  column_configs << {:field_type => 'text', :field_name => 'season', :column_caption => 'Season'}

  get_data_grid(data_set,column_configs)
end



  def build_carton_grading_rule_header_dm_grid(data_set, stat, columns_list, can_edit, can_delete, grid_configs)

    column_configs = []
    action_configs = []

    # ----------------------
    # define action columns
    # ----------------------
    if can_edit
      action_configs << {:field_type => 'action',:field_name => 'edit carton_grading_rule_header',
        :column_caption => 'Edit',
        :settings =>
       {:link_text => 'edit',
        :link_icon => 'edit',
        :target_action => 'edit_carton_grading_rule_header',
        :id_column => 'id'}}
    end

    if can_delete
      action_configs << {:field_type => 'action',:field_name => 'delete carton_grading_rule_header',
        :column_caption => 'Delete',
        :settings =>
       {:link_text => 'delete',
        :link_icon => 'delete',
        :target_action => 'delete_carton_grading_rule_header',
        :id_column => 'id'}}
    end

    #action_configs << {:field_type => 'separator'} if can_edit || can_delete
    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

    # Build all other columns from the dataminer yml file.
    build_generic_column_configs(data_set, column_configs, stat, columns_list, grid_configs)

    # Get any other datagrid options from the grid_configs...
    opts = build_grid_options_from_grid_configs(grid_configs)

    get_data_grid(data_set, column_configs, nil, true, nil, opts)
  end

end
