module RmtProcessing::GradingRuleHelper

  def build_carton_grading_rule_form(grading_rule, action, caption, is_edit = nil, is_new = nil)
    field_configs = Array.new
    sizes      = ActiveRecord::Base.connection.select_all("select size_code from sizes").map{|x|x['size_code']}
    grades     = ActiveRecord::Base.connection.select_all("select grade_code from grades").map{|x|x['grade_code']}
    #varieties  = ActiveRecord::Base.connection.select_all("select distinct variety_short_long from cartons").map{|x|x['variety_short_long']}
    #line_types = ActiveRecord::Base.connection.select_all("select distinct line_code from cartons").map{|x|x['line_code']}
    classes    = ActiveRecord::Base.connection.select_all("select product_class_code from product_classes").map{|x|x['product_class_code']}

    varieties  = ActiveRecord::Base.connection.select_all("select marketing_variety_code,marketing_variety_description from marketing_varieties
                                             ").map{|b|b['marketing_variety_code'] + "_" + b['marketing_variety_description']}
    line_types = ["","Primary Line","Secondary Line"]




    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'season'} if is_edit
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'track_slms_indicator_code'} if is_edit
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'size', :settings=>{:list=>sizes,:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'grade', :settings=>{:list=>grades,:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'variety', :settings=>{:list=>varieties,:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'line_type', :settings=>{:list=>line_types,:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'product_class_code', :settings=>{ :label_caption=> "class",:list=>classes,:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'TextField',:hide => true, :field_name=>'track_slms_indicator_code'} if is_new
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'new_class'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'new_size'}

    # field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'new_class', :settings=>{:list=>classes,:show_label=>true}}
    # field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'new_size', :settings=>{:list=>sizes,:show_label=>true}}
    build_form(grading_rule, field_configs, action, 'grading_rule', caption, is_edit)
  end

  def build_grading_rules_grid(data_set)
    column_configs = []
    action_configs = get_action_configs
    grid_command =    {:field_type=>'link_window_field',:field_name =>'new_grading_rule',
                       :settings =>
                           {
                               :host_and_port =>request.host_with_port.to_s,
                               :controller =>request.path_parameters['controller'].to_s,
                               :target_action =>'new_carton_grading_rule',
                               :link_text => 'new_rule',
                               :id_value=>"#{session[:active_doc]['rule_header']}"
                           }}
    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}}
    column_configs << {:field_type => 'text',:field_name => 'activated',:column_caption=>'active' ,:data_type => 'boolean',:col_width=>65}
    column_configs << {:field_type => 'text',:field_name => 'season' ,:col_width=>70}
    column_configs << {:field_type => 'text',:field_name => 'track_slms_indicator_code' ,:col_width=>130}
    column_configs << {:field_type => 'text',:field_name => 'size' ,:col_width=>60}
    column_configs << {:field_type => 'text',:field_name => 'grade' ,:col_width=>60}
    column_configs << {:field_type => 'text',:field_name => 'variety' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'line_type' ,:col_width=>100}
    column_configs << {:field_type => 'text',:field_name => 'new_class' ,:col_width=>80}
    column_configs << {:field_type => 'text',:field_name => 'new_size' ,:col_width=>80}
    column_configs << {:field_type => 'text',:field_name => 'product_class_code' ,:column_caption=>'class',:col_width=>70}
    column_configs << {:field_type => 'text',:field_name => 'created_at' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'created_by' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'updated_by' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'updated_at' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'description' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'deactivated_at' ,:col_width=>130}
    column_configs << {:field_type => 'text',:field_name => 'activated_at' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'id' ,:col_width=>170}
    set_grid_min_height(80)
    set_grid_min_width(300)
    hide_grid_client_controls
    return get_data_grid(data_set,column_configs,nil,true,grid_command)
  end


  def build_grading_rule_headers_grid(data_set)
    action_configs=[]
    column_configs = []

    action_configs << {:field_type => 'link_window', :field_name => 'rules',:col_width=>100,
                       :settings =>{:link_icon => 'rules',:target_action => 'list_grading_rules',:link_text => 'rules',
                                    :id_column => 'id'}}

    action_configs << {:field_type => 'action', :field_name => 'activate', :col_width => 33,
                       :settings => {:link_icon => 'activate',
                       :null_test => "['activated'] == 't'",:target_action => 'activate_carton_grading_rule_header',
                                      :link_text => 'activate',:id_column => 'id'}}

    action_configs << {:field_type => 'action', :field_name => 'delete', :col_width => 33,
                       :settings => { :null_test => "['activated'] == 't'", :link_icon => 'delete',:target_action => 'delete_carton_grading_rule_header', :link_text => 'delete', :link_icon => 'delete',:id_column => 'id'}}

    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}}
    column_configs << {:field_type => 'text',:field_name => 'activated',:column_caption=>'active' ,:data_type => 'boolean',:col_width=>80}
    column_configs << {:field_type => 'text',:field_name => 'season' ,:col_width=>80}
    column_configs << {:field_type => 'text',:field_name => 'created_at' ,:col_width=>170}
    column_configs << {:field_type => 'text',:field_name => 'created_by' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'updated_by' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'updated_at' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'description' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'deactivated_at' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'activated_at' ,:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'deactivated',:hide => true}
    column_configs << {:field_type => 'text',:field_name => 'is_active_header',:hide => true}

    column_configs << {:field_type => 'text',:field_name => 'id' ,:col_width=>170}
    set_grid_min_height(80)
    set_grid_min_width(300)
    hide_grid_client_controls
    return get_data_grid(data_set,column_configs, MesScada::GridPlugins::RmtProcessing::CartonGradingRuleHeaderGridPlugin.new(self, request),true)
  end

  def get_action_configs()
    action_configs=[]
    # --null_test: if true return an empty result
    action_configs << {:field_type => 'action', :field_name => 'activate', :col_width => 70,:settings =>{
                      :null_test => "['activated'] == 't' || ['activated'] == true ||  ['is_active_header'] == 't' || ['is_active_header'] == true",
                      :link_text => 'activate', :link_icon => 'view',:target_action => 'activate_carton_grading_rule', :id_column => 'id'}}

     action_configs << {:field_type => 'action', :field_name => 'deactivate', :col_width => 70,:settings =>{
                        :null_test => " ['activated'] == false || ['is_active_header'] == false",
                         :link_text => 'deactivate', :link_icon => 'view',:target_action => 'deactivate_carton_grading_rule', :id_column => 'id'}}

    action_configs << {:field_type => 'link_window', :field_name => 'edit', :col_width => 35,
                       :settings =>{:link_text => 'edit', :link_icon => 'edit',:target_action => 'edit_carton_grading_rule',:id_column => 'id'}}

    action_configs << {:field_type => 'action', :field_name => 'delete', :col_width => 33, :settings => { :null_test => "['activated'] == 't'",
                       :target_action => 'delete_carton_grading_rule', :link_text => 'delete', :link_icon => 'delete',:id_column => 'id'}}

    action_configs
  end


end

