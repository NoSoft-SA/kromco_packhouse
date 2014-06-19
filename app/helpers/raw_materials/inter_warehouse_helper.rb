module RawMaterials::InterWarehouseHelper

     def  build_vehicle_jobs_grid(data_set,can_edit,can_delete)

	column_configs = Array.new

column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'print_tripsheet',
             :settings =>
                {:link_text => 'print_tripsheet',
               :target_action => 'print_tripsheet',
               :id_column => 'id'}}


	  column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'vehicle_job_number'}
    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'date_time_loaded'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'date_time_offloaded'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'vehicle_job_type_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}
#	----------------------
#	define action columns
#	----------------------

 return get_data_grid(data_set,column_configs)


end

end
