module Tools::ProcessesHelper

  def process_sub_tree(process,parent_node)
    if(process.friendly_name)
      process_nose_name = process.friendly_name
    else
      process_nose_name = process.status_type_code
    end
    process_node = parent_node.add_child(process_nose_name,"process",process.id.to_s)
    statuses = Status.find_all_by_status_type_code(process.status_type_code)

    process_statuses_node = process_node.add_child("statuses","statuses",process.id.to_s)# if(statuses.length > 0)
    statuses.each do |status|
      status_node = process_statuses_node.add_child(status.status_code,"status",status.id.to_s)
      alerts_node = status_node.add_child("alerts","alerts",status.id.to_s)

      process_alert_defs = ProcessAlertDef.find_all_by_status_id(status.id)
      process_alert_defs.each do |process_alert_def|
        process_alert_def_node = alerts_node.add_child(process_alert_def.process_alert_name,"process_alert",process_alert_def.id.to_s)
      end

    end

    sub_processes = StatusType.find_all_by_parent_id(process.id)
    sub_processes.each do |sub_process|
      process_sub_tree(sub_process,process_node)
    end
  end

  def build_list_processes_tree(data_set)
    begin
      root_node     = ApplicationHelper::TreeNode.new("processes", "root_process", true, "processes")
      tree                 = ApplicationHelper::TreeView.new(root_node, "processes")

      data_set.each do |process|
        process_sub_tree(process,root_node)
      end

      root_menu = ApplicationHelper::ContextMenu.new("root_process", "processes")
      root_menu.add_command("new process", url_for(:action => "new_process"))
      
      process_menu = ApplicationHelper::ContextMenu.new("process", "processes")
      process_menu.add_command("new sub process", url_for(:action => "new_sub_process"))
      process_menu.add_command("view history", url_for(:action => "view_status_history"))
      process_menu.add_command("remove", url_for(:action => "delete_process"))
      process_menu.add_command("edit", url_for(:action => "edit_process"))

      statuses_menu = ApplicationHelper::ContextMenu.new("statuses", "processes")
      statuses_menu.add_command("add", url_for(:action => "new_status"))
      
      status_menu = ApplicationHelper::ContextMenu.new("status", "processes")
      status_menu.add_command("edit", url_for(:action => "edit_process_status"))
      status_menu.add_command("delete", url_for(:action => "delete_process_status"))

      alerts_menu = ApplicationHelper::ContextMenu.new("alerts", "processes")
      alerts_menu.add_command("new alert", url_for(:action => "new_process_alert"))

      process_alert_menu = ApplicationHelper::ContextMenu.new("process_alert", "processes")
      process_alert_menu.add_command("remove", url_for(:action => "delete_process_alert_def"))
      process_alert_menu.add_command("edit/setup", url_for(:action => "manage_process_alert_def"))
      process_alert_menu.add_command("view alerts", url_for(:action => "view_alerts"))

      tree.add_context_menu(process_alert_menu)
      tree.add_context_menu(statuses_menu)
      tree.add_context_menu(status_menu)
      tree.add_context_menu(process_menu)
      tree.add_context_menu(root_menu)
      tree.add_context_menu(alerts_menu)
      tree.render
    rescue
      raise "The processes tree could not be rendered. Exception reported is \n" + $!
    end
  end

  def build_process_form(status_type,action,caption,is_edit = nil,is_create_retry = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
    session[:status_type_form]= Hash.new
    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
    field_configs = Array.new
    if(is_edit)
      field_configs << {:field_type => 'LabelField',
            :field_name => 'status_type_code',
            :settings=>{:label_caption=>'process name'}}

      field_configs << {:field_type => 'LabelField',
            :field_name => 'ar_class_name'}
    else
      field_configs << {:field_type => 'TextField',
            :field_name => 'status_type_code',
            :settings=>{:label_caption=>'process name'}}

      field_configs << {:field_type => 'TextField',
            :field_name => 'ar_class_name'}
    end
    
    field_configs << {:field_type => 'TextField',
            :field_name => 'friendly_name'}

    field_configs << {:field_type => 'TextField',
            :field_name => 'description'}

    field_configs << {:field_type => 'CheckBox',
            :field_name => 'ignore_status_sequence'}

    build_form(status_type,field_configs,action,'status_type',caption,is_edit)
    
  end

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
                      :settings => {:static_value => session[:status_type_code], :show_label => true,:label_caption=>'process name'}}


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

    field_configs << {:field_type => 'TextField',
              :field_name => 'position'}

    field_configs << {:field_type => 'CheckBox',
              :field_name => 'is_error_status'}

    field_configs << {:field_type => 'CheckBox',
              :field_name => 'is_terminal_status'}

    build_form(status,field_configs,action,'status',caption,is_edit)

    end

  def build_view_object_history_grid(data_set)
    #require File.dirname(__FILE__) + "/../../../app/helpers/tools/process_plugins.rb"

    ids_where_clause = "where"
    data_set.each do |trans_status|
      ids_where_clause = ids_where_clause + " parent_id=" + trans_status.id.to_s + " or"
    end
    ids_where_clause = ids_where_clause.slice(0,ids_where_clause.length-2)
    puts"IDs's : " + ids_where_clause
    object_transaction_statuses_children = TransactionStatus.find_by_sql("
                                              select status_type_code
                                              from transaction_statuses
                                              #{ids_where_clause} 
                                              group by status_type_code")

    column_configs = Array.new

    data_set[0].attributes.keys.each do |key|
      if(key != "parent_id" && key != "object_id" && key != "id")
        column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key.to_s} #if(key != "parent_id" && key != "object_id" && key != "id")
      end
    end


    column_configs << {:field_type => 'link_window', :field_name => 'parent',
                                       :settings =>
                                       {:link_text => 'parent',
                                        :target_action => "view_transaction_status_parent",
                                        :id_column => 'parent_id'}}

    if(object_transaction_statuses_children.length > 0)

      object_transaction_statuses_children.each do |object_transaction_status_children|
        column_configs << {:field_type => 'link_window', :field_name => "child_#{object_transaction_status_children.status_type_code}_transaction_statuses",
                                       :settings =>
                                       {:link_text=>"",
                                       :target_action => "view_transaction_status_parent",
                                       :id_column => 'id'}}
      end
    end
    
    set_grid_min_height(300)
    set_grid_min_width(950)
     hide_grid_client_controls()
    return get_data_grid(data_set,column_configs, MesScada::GridPlugins::Tools::TransactionStatusesGridPlugin.new(self, request))
  end

  def build_transaction_statuses_grid(data_set)

    column_configs = Array.new

    data_set[0].keys.each do |key|
      column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key.to_s}#if(key != "parent_id" && key != "object_id" && key != "id")
    end


    column_configs << {:field_type => 'link_window', :field_name => 'rails_object',
                                       :settings =>
                                       {:link_text => 'view record',
                                        :target_action => "view_transaction_status_process_record",
                                        :id_column => 'object_id'}}

    column_configs << {:field_type => 'link_window', :field_name => 'status_history',
                                           :settings =>
                                           {:link_text => 'view',
                                            :target_action => "view_child_transaction_status_history",
                                            :id_column => 'object_id'}}

    set_grid_min_height(300)
    set_grid_min_width(950)
    hide_grid_client_controls()
    return get_data_grid(data_set,column_configs, MesScada::GridPlugins::Tools::ChildTransactionStatusesGridPlugin.new(self, request),true)
  end

  def build_process_alert_def_form(process_alert_def,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
#    triggers = ['on_status_reached','status_not_reached','status_not_changed']
    triggers = ProcessAlertTrigger.find(:all).map{|p| p.trigger_name}
    session[:status_type_form]= Hash.new
    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
    field_configs = Array.new
    field_configs << {:field_type => 'DropDownField',
            :field_name => 'trigger_name',
            :settings=>{:list=>triggers,:label_caption=>"trigger"}}

    field_configs << {:field_type => 'DropDownField',
            :field_name => 'mode',
            :settings=>{:list=>["active",'inactive','paused'],:no_empty=>true}}

    field_configs << {:field_type => 'TextField',
            :field_name => 'description'}

    build_form(process_alert_def,field_configs,action,'process_alert_def',caption,is_edit)

  end

  def build_manage_process_alert_def_form(process_alert_def,action,caption)

    status = Status.find(process_alert_def.status_id)
    
    field_configs = Array.new
    
    field_configs << {:field_type => 'LabelField',
            :field_name => 'process_name',
            :settings=>{:static_value => status.status_type_code,:show_label=>true}}
    
    field_configs << {:field_type => 'LabelField',
            :field_name => 'trigger_name',
            :settings=>{:show_label=>true}}

    field_configs << {:field_type => 'DropDownField',
                :field_name => 'mode',
                :settings=>{:list=>["active",'inactive','paused'],:no_empty=>true}}
    
    field_configs << {:field_type => 'LabelField',
            :field_name => process_alert_def.trigger_name,
            :settings=>{:static_value => status.status_code,:show_label=>true}}


    field_configs << {:field_type => 'TextField',
            :field_name => 'description'}

    field_configs << {:field_type => 'TextField',
            :field_name => 'alert_time_frame',
            :settings=>{:label_caption=>"process_interval(hours)"}}
    
    field_configs << {:field_type => 'TextField',
            :field_name => 'process_interval',
            :settings=>{:label_caption=>"process_interval(minutes)"}}

    field_configs << {:field_type => 'CheckBox',
            :field_name => 'send_email_alert'}

    field_configs << {:field_type => 'TextArea',
            :field_name => 'email_recipients'}

    field_configs << {:field_type => 'TextArea',
            :field_name => 'email_message'}

    build_form(process_alert_def,field_configs,action,'process_alert_def',caption)
  end

  def build_parent_view_transaction_status_record_form(transaction_status, action, caption)
    field_configs = []

    id_value = "#{transaction_status.the_object_id}|#{transaction_status.ar_class_name}"
    field_configs << {:field_type => 'LabelField',:field_name => 'created_on'}
    field_configs << {:field_type => 'LabelField',:field_name => 'parent_id'}
    field_configs << {:field_type => 'LabelField',:field_name => 'status_code'}
    field_configs << {:field_type => 'LabelField',:field_name => 'status_type_code'}
    field_configs << {:field_type => 'LabelField',:field_name => 'username'}
    field_configs << {:field_type => 'LinkWindowField', :field_name => '',
                                             :settings => {
                                                     :controller =>"tools/processes",
                                                     :target_action => 'view_transaction_status_object', :link_text => "view_object_record",
                                                     :id_value => id_value
                                                   }}

    build_form(transaction_status,field_configs,action,'transaction_status',caption)
  end
end