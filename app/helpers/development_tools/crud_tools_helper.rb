module DevelopmentTools::CrudToolsHelper
    
    
   def create_form(target_action,get_func_area = nil)
  	
  	field_configs = Array.new
  	index = 0
  	field_configs[index] = {:field_type => 'TextField',
  	                    :field_name => 'table_name'}
  	 
  	if get_func_area
  	   index += 1
  	   field_configs[index] = {:field_type => 'TextField',
  	                    :field_name => 'functional_area'}
  	end
  	
  	if target_action != "save_security_settings"         
  	   index += 1
  	   field_configs[index] = {:field_type => 'CheckBox',
  	                    :field_name => 'create_file'}
  	
  	   index += 1
  	   field_configs[index] = {:field_type => 'CheckBox',
  	                    :field_name => 'show_code'}
  	                    
  	   index += 1
  	   field_configs[index] = {:field_type => 'CheckBox',
  	                    :field_name => 'create_code_file'}
  	                                     
  	 end                                         
  	build_form(nil,field_configs,target_action,'model',target_action)
  	
  end

   #MM082017 - list_project_files
   def build_list_directories_form(directories,action,caption)

     field_configs = Array.new

     field_configs << {:field_type => 'TextField',
                       :field_name => 'directory_name?required'}

     field_configs << {:field_type => 'CheckBox',
                       :field_name => 'include_files'}

     field_configs << {:field_type => 'TextField',
                       :field_name => 'wild_card'}

     build_form(directories,field_configs,action,'project_files',caption)

   end


end
