module Security::PermissionsHelper

def get_permissions_grid(data_set)
  	
  	column_configs = Array.new
  	
  	column_configs[0]= {:field_type => "text",:field_name => "security_permission"}
  	
  	column_configs[1]= {:field_type => "action",:field_name => "delete permission",
  								   :settings => 
  								   		{:link_text => "delete",
  								   		 :target_action => "delete_permission",
  								   	     :id_column => "id"} }
  	
  	return get_data_grid(data_set,column_configs)
  	
 end

 def build_permission_form(action,submit_caption,send_id = nil)
  	
  	field_configs = Array.new
  	
  	field_configs[0] = {:field_type => 'TextField',
  	                    :field_name => 'security_permission'}
  	 
  	                                   
  	build_form(@permission,field_configs,action,'permission',submit_caption,send_id)
  	
  end


end
