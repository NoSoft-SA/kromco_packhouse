module Fg::IwHelper

  #==========================================
  #  VEHICLES
  #==========================================
  def build_vehicle_form(vehicle,action,caption, is_edit=nil,is_create_retry=nil)
    field_configs = Array.new
	  
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'vehicle_code'}
	  field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'vehicle_description'}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'vehicle_registration_number'}
	 
	  build_form(vehicle,field_configs,action,'vehicle',caption,is_edit)
  end

  def build_vehicles_grid(data_set,can_edit,can_delete)
    column_configs = Array.new
    	column_configs[0] = {:field_type => 'text',:field_name => 'vehicle_code'}
    	column_configs[1] = {:field_type => 'text',:field_name => 'vehicle_registration_number'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'vehicle_description'}
    	
      #	----------------------
      #	define action columns
      #	----------------------
      if can_edit
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit vehicle',
          :settings =>
             {:link_text => 'edit',
            :target_action => 'edit_vehicle',
            :id_column => 'id'}}
      end

      if can_delete
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete vehicle',
          :settings =>
             {:link_text => 'delete',
            :target_action => 'delete_vehicle',
            :id_column => 'id'}}
      end

      return get_data_grid(data_set,column_configs)
  end

end