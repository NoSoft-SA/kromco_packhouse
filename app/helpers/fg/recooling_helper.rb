module Fg::RecoolingHelper
  
  def build_jobs_grid(data_set)

   column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'job_number'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'date_created'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'job_type_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'current_job_status'}
   
     column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view_reports',
      	   :settings =>
      		 {:link_text => 'view_reports',
      		  :target_action => 'view_reports',
      		  :id_column => 'id'}}


    key_based_access = true
    key_based_access = @key_based_access if @key_based_access



   return get_data_grid(data_set,column_configs,nil,key_based_access)
 end






end
