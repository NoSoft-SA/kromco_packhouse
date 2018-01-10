module DevelopmentTools::LogDataChangeHelper

  def build_log_data_change_form(log_data_change,action,caption,is_edit = nil,is_create_retry = nil)
    field_configs = []
    field_configs << {:field_type => 'TextField',
                      :field_name => 'type_of_change',
                      :settings   => {:size => 100}}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'ref_nos',
                      :settings   => {:size => 100}}

    field_configs << {:field_type => 'TextArea',
                      :field_name => 'notes',
                      :settings   => {:cols => 100, :rows => 20}}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'user_name'}

    construct_form(log_data_change,field_configs,action,'log_data_change',caption,is_edit)
  end

  def build_log_data_change_grid(data_set,can_edit,can_delete)

    column_configs = []
    action_configs = []

    action_configs << {:field_type     => 'link_window',:field_name => 'view log_data_change',
                       :column_caption => 'view',
                       :settings       =>
    {:link_text     => 'view',
     :link_icon     => 'view',
     :target_action => 'view_log_data_change',
     :id_column     => 'id'}}

    if can_edit
      action_configs << {:field_type => 'separator'}

      action_configs << {:field_type     => 'action',:field_name => 'edit log_data_change',
                         :column_caption => 'Edit',
                         :settings       =>
      {:link_text     => 'edit',
       :link_icon     => 'edit',
       :target_action => 'edit_log_data_change',
       :id_column     => 'id'}}
    end

    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

    column_configs << {:field_type => 'text', :field_name => 'type_of_change', :column_caption => 'Type of change', :column_width => 300}
    column_configs << {:field_type => 'text', :field_name => 'ref_nos', :column_caption => 'Ref nos', :column_width => 200}
    column_configs << {:field_type => 'text', :field_name => 'notes', :column_caption => 'Notes', :column_width => 400, :truncate => true}
    column_configs << {:field_type => 'text', :field_name => 'user_name', :column_caption => 'User name'}
    column_configs << {:field_type => 'text', :field_name => 'created_at', :column_caption => 'Created At'}

    grid_command = {:field_type => 'link_window_field', :field_name => 'new_log',
                    :settings   => {
                    :target_action => 'new_log_data_change',
                    :link_text     => "New Data Change Log"}
                   }

    get_data_grid(data_set,column_configs, nil, true, grid_command)
  end

  #MM062017 - Enhance the 'log_data_changes' UI to view the 'notes' column as a structured HTML table and a grid view(optional) link that user can click
  def build_show_in_grid_display(data_set,keys)

    column_configs = []

    keys.each do |key|
      field_name = key.to_s.strip
      column_configs << {:field_type => 'text', :field_name => field_name, :column_width => 200}
    end

    get_data_grid(data_set,column_configs, nil, true)
  end

end
