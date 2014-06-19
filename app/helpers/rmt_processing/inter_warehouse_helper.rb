module RmtProcessing::InterWarehouseHelper

     def  build_vehicle_jobs_grid(data_set,can_edit,can_delete)

	column_configs = Array.new

column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'print_tripsheet',
             :settings =>
                {:image => 'printer',
               :target_action => 'print_tripsheet',
               :id_column => 'id'}}


	  column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'vehicle_job_number', :col_width=> 52}
    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'date_time_loaded', :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'date_time_offloaded', :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'vehicle_job_type_code', :col_width=> 45}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_at_location', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_by', :col_width=> 57}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id', :col_width=> 45}
#	----------------------
#	define action columns
#	----------------------
 
 return get_data_grid(data_set,column_configs)


end

end
