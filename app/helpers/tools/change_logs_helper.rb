module Tools::ChangeLogsHelper

  def build_find_change_logs_form(action,caption)
    field_configs = []

    field_configs << {:field_type => 'TextField',
        :field_name => 'record_rails_id',
        :settings => {:label_caption=>'record id',
                      :lookup=>true,:lookup_search_file=>"change_logs",:select_column_name=>'record_rails_id'}}

    field_configs << {:field_type => 'TextField',
        :field_name => 'xaction_buz_name',
        :settings => {:lookup=>true,:lookup_search_file=>"change_logs",:select_column_name=>'transaction_business_name',
                      :send_fields=>'record_rails_id,doc_name',
                      :submit_to=>"/change_management/change_logs/lookup_submit_to"}}

    field_configs << {:field_type => 'TextField',
        :field_name => 'doc_name',
        :settings => {:lookup=>true,:lookup_search_uri=>"change_management/change_logs/toets",
                      :send_fields=>'record_rails_id,xaction_buz_name'}}

    build_form(nil,field_configs,action,'change_log',caption,false)
  end

  def toets(change_log,action,caption)
    field_configs = []

    field_configs << {:field_type => 'LabelField',
        :field_name => 'record_rails_id'}

    field_configs << {:field_type => 'LabelField',
        :field_name => 'transaction_business_name'}

	  build_form(change_log,field_configs,action,'change_log',caption,false)

  end

  def build_record_form(active_record_instance,action,caption,form_fields)
    field_configs = []

    form_fields.store("update_field",active_record_instance.update_field)
    form_fields.store("id",nil)

    form_fields.keys.each do |key|
      if(key.to_s == "update_field")
            field_configs << {:field_type => 'HiddenField',:field_name => key.to_s}
      else
        field_configs << {:field_type => 'TextField',:field_name => key.to_s}
      end
    end

    build_form(active_record_instance,field_configs,action,'hash_object',caption,false)
  end

  def build_change_logs_grid(data_set, can_edit, can_delete)
    require File.dirname(__FILE__) + "/../../../app/helpers/tools/change_logs_grid_plugin.rb"

    column_configs = Array.new


   column_configs << {:field_type => 'link_window', :field_name => "deleted_record", :col_width=>150 ,
                      :settings =>
                          {:link_text => '',
                           :target_action => "view_change_log_#{"deleted_record"}",
                           :id_column => 'id',
                           :id_value => "deleted_record"}}



  column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'compare',:col_width=>150 ,
                                               :settings =>
                                               {:link_text => '',
                                                :target_action => 'compare_change_logs',
                                                :id_column => 'id'}}

   data_set[0].keys.each do |key|
      column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key.to_s,:col_width=>150 ,}
   end

    get_data_grid(data_set, column_configs, ToolsPlugins::ChangeLogsGridPlugin.new(self, request) , true)

  end

  def build_view_change_log_form(hash_object,change_log_hash)
    field_configs = []

    change_log_hash.keys.each do |key|
      field_configs << {:field_type => 'LabelField',
          :field_name => key.to_s}
    end

    build_form(hash_object,field_configs,nil,'hash_object',"",false)
  end

end