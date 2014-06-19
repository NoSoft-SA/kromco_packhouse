module Services::FtaReportsHelper
  def build_fta_reports_grid(instruments_fta_sessions)
    column_configs = Array.new
 
    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view_report',
                                             :settings =>
                                             {:link_text => 'view',
                                              :target_action => 'view_fta_report',
                                              :id_column => 'id',
                                              :window_width =>700,
                                              :window_height =>700}}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'test_type'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_id'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'user_name'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on'}
    return get_data_grid(instruments_fta_sessions, column_configs, nil)
  end

  def build_rfm_reports_grid(instruments_rfm_sessions)
    column_configs = Array.new

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view_report',
                                             :settings =>
                                             {:link_text => 'view',
                                              :target_action => 'view_rfm_report',
                                              :id_column => 'id',
                                              :window_width =>700,
                                              :window_height =>700}}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'test_type'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_id'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'user_name'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on'}
    return get_data_grid(instruments_rfm_sessions, column_configs, nil)
  end
end
