module Diagnostics::RailsHelper

def build_rails_grid(data_set, can_edit, can_delete)
        
        column_configs = Array.new
        
        data_set.each do |record|
        
            if record.description!=nil
                record.description = h(truncate(record.description, Globals.get_diagnostics_truncate_size()))
            end
            if record.stack_trace!=nil
                record.stack_trace = h(truncate(record.stack_trace,Globals.get_diagnostics_truncate_size()))
            end
        end
        
         column_configs[0] = {:field_type => 'action',:field_name => 'details',
      	   :settings => 
      		 {:link_text =>'view details',
      		  :target_action => 'view_details',
      		  :id_column => 'id'}}
       
    	column_configs[1] = {:field_type => 'text',:field_name => 'error_type'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'description'}
    	column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
    	column_configs[4] = {:field_type => 'text',:field_name => 'created_on'}
    	column_configs[5] = {:field_type => 'text',:field_name => 'logged_on_user'}
    	column_configs[6] = {:field_type => 'text',:field_name => 'controller_name'}
    	column_configs[7] = {:field_type => 'text',:field_name => 'action_name'}
    	
    	
    #----------------------
     # define action columns
    #----------------------
        
       
      	
      		  
    #----------------------
     # action columns
    #----------------------
           
        return get_data_grid(data_set,column_configs)
end


def view_rails_error_details_form(rails,action)
        field_configs = Array.new
        
        field_configs[0] =  {:field_type => 'LabelField',
  						:field_name => 'error_type'}
						
    	field_configs[1] =  {:field_type => 'LabelField',
    						:field_name => 'description'}
    				
     
    	field_configs[2] =  {:field_type => 'LabelField',
    						:field_name => 'stack_trace'}
    						
        field_configs[3] =  {:field_type => 'LabelField',
    						:field_name => 'created_on'}
    						
    	field_configs[4] =  {:field_type => 'LabelField',
    						:field_name => 'logged_on_user'}
    						
    	field_configs[5] =  {:field_type => 'LabelField',
    						:field_name => 'controller_name'}
    						
    	field_configs[6] =  {:field_type => 'LabelField',
    						:field_name => 'action_name'}
    	
    	build_form(rails,field_configs,action,'rails_error',"back")
end


end