module RmtProcessing::CartonGradingRuleHelper


 def build_carton_grading_rule_form(carton_grading_rule,action,caption,is_edit = nil,is_create_retry = nil)
#  --------------------------------------------------------------------------------------------------
#  Define a set of observers for each composite foreign key- in effect an observer per combo involved
#  in a composite foreign key
#  --------------------------------------------------------------------------------------------------
  session[:carton_grading_rule_form]= Hash.new
  created_ats = CartonGradingRuleHeader.find_by_sql('select distinct created_at from carton_grading_rule_headers').map{|g|[g.created_at]}
#  ---------------------------------
#   Define fields to build form from
#  ---------------------------------
   field_configs = []
  field_configs << {:field_type => 'TextField',
            :field_name => 'size'}

  field_configs << {:field_type => 'TextField',
            :field_name => 'grade'}

  field_configs << {:field_type => 'TextField',
            :field_name => 'variety'}

  field_configs << {:field_type => 'TextField',
            :field_name => 'track_indicator'}

  field_configs << {:field_type => 'TextField',
            :field_name => 'line_type'}

#  ----------------------------------------------------------------------------------------------------
#  Combo field to represent foreign key (carton_grading_rule_header_id) on related table: carton_grading_rule_headers
#  -----------------------------------------------------------------------------------------------------
  field_configs << {:field_type => 'DropDownField',
            :field_name => 'created_at',
            :settings => {:list => created_ats}}


  construct_form(carton_grading_rule,field_configs,action,'carton_grading_rule',caption,is_edit)

end


 def build_carton_grading_rule_search_form(carton_grading_rule,action,caption,is_flat_search = nil)
#  --------------------------------------------------------------------------------------------------
#  Define an observer for each index field
#  --------------------------------------------------------------------------------------------------
  session[:carton_grading_rule_search_form]= Hash.new
  #generate javascript for the on_complete ajax event for each combo
  #Observers for search combos
#  ----------------------------------------
#   Define search fields to build form from
#  ----------------------------------------
field_configs = []
  sizes = CartonGradingRule.find_by_sql('select distinct size from carton_grading_rules').map{|g|[g.size]}
  field_configs << {:field_type => 'DropDownField',
            :field_name => 'size',
            :settings => {:list => sizes}}

  construct_form(carton_grading_rule,field_configs,action,'carton_grading_rule',caption,false)

end



 def build_carton_grading_rule_grid(data_set,can_edit,can_delete)

  column_configs = []
  action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
  if can_edit
    action_configs << {:field_type => 'action',:field_name => 'edit carton_grading_rule',
      :column_caption => 'Edit',
      :settings =>
         {:link_text => 'edit',
        :link_icon => 'edit',
        :target_action => 'edit_carton_grading_rule',
        :id_column => 'id'}}
  end

  if can_delete
    action_configs << {:field_type => 'action',:field_name => 'delete carton_grading_rule',
      :column_caption => 'Delete',
      :settings =>
         {:link_text => 'delete',
        :link_icon => 'delete',
        :target_action => 'delete_carton_grading_rule',
        :id_column => 'id'}}
  end

  #action_configs << {:field_type => 'separator'} if can_edit || can_delete

  column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

  column_configs << {:field_type => 'text', :field_name => 'size', :column_caption => 'Size'}
  column_configs << {:field_type => 'text', :field_name => 'grade', :column_caption => 'Grade'}
  column_configs << {:field_type => 'text', :field_name => 'variety', :column_caption => 'Variety'}
  column_configs << {:field_type => 'text', :field_name => 'track_indicator', :column_caption => 'Track indicator'}
  column_configs << {:field_type => 'text', :field_name => 'line_type', :column_caption => 'Line type'}
  column_configs << {:field_type => 'text', :field_name => 'updated_by', :data_type => 'date', :column_caption => 'Updated by'}
  column_configs << {:field_type => 'text', :field_name => 'deactivated_at', :data_type => 'date', :column_caption => 'Deactivated at'}
  column_configs << {:field_type => 'text', :field_name => 'activated_at', :data_type => 'date', :column_caption => 'Activated at'}

  get_data_grid(data_set,column_configs)
end



  def build_carton_grading_rule_dm_grid(data_set, stat, columns_list, can_edit, can_delete, grid_configs)

    column_configs = []
    action_configs = []

    # ----------------------
    # define action columns
    # ----------------------
    if can_edit
      action_configs << {:field_type => 'action',:field_name => 'edit carton_grading_rule',
        :column_caption => 'Edit',
        :settings =>
       {:link_text => 'edit',
        :link_icon => 'edit',
        :target_action => 'edit_carton_grading_rule',
        :id_column => 'id'}}
    end

    if can_delete
      action_configs << {:field_type => 'action',:field_name => 'delete carton_grading_rule',
        :column_caption => 'Delete',
        :settings =>
       {:link_text => 'delete',
        :link_icon => 'delete',
        :target_action => 'delete_carton_grading_rule',
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
