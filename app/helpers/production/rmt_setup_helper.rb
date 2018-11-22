module Production::RmtSetupHelper
 
 
 
 def build_bintip_criterium_form(bintip_criteria_setup,action,caption,is_edit = nil,is_create_retry = nil,is_view = nil)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    action = nil if is_view



	 field_configs = Array.new
	field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'farm_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'commodity_code'}


    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'variety_code'}


  if bintip_criteria_setup.is_a?(RunBintipCriterium) && bintip_criteria_setup.production_run.is_dp_run?
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'treatment_code'}

      field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                                :field_name => 'size_code'}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'class_code'}

  else

    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
              :field_name => 'treatment_code'}

    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
                                               :field_name => 'track_indicator_code'}

      field_configs[field_configs.length()] =  {:field_type => 'CheckBox',
                                                :field_name => 'size_code'}

      field_configs[field_configs.length()] = {:field_type => 'CheckBox',
                                               :field_name => 'class_code'}


   end
  field_configs[field_configs.length()] =  {:field_type => 'CheckBox',
                                              :field_name => 'rmt_product_type_code'}





	field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'class_code'}

	field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'pc_code'}



	field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'cold_store_code'}


	field_configs[field_configs.length()] =  {:field_type => 'CheckBox',
						:field_name => 'season_code'}

		field_configs[field_configs.length()] = {:field_type => 'CheckBox',
																						 :field_name => 'track_indicator_code'}


    field_configs[field_configs.length()] =  {:field_type => 'CheckBox',
                         :field_name => 'rmt_product_type_code'}

    field_configs[field_configs.length()] =  {:field_type => 'CheckBox',
                         :field_name => 'ripe_point_code'}

						
	build_form(bintip_criteria_setup,field_configs,action,'bintip_criteria_setup',caption,is_edit)

end


 def build_rmt_setup_form(rmt_setup,is_view = nil)

   
    action = "save_rmt_setup"
    action = nil if is_view == true
    
   
	ca_cold_rooms = Store.find_all_by_store_type_code("cold_store").map{|g|[g.store_code]}
	ca_cold_rooms.unshift("<empty>")
	
	track_indicator_codes = TrackIndicator.find_all_by_commodity_code_and_rmt_variety_code(rmt_setup.commodity_code,rmt_setup.variety_code).map{|g|[g.track_indicator_code]}
	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new


    field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}
						
	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'rmt_product_code'}
					
	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'commodity_code'}
 
	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'variety_code'}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (treatment_id) on related table: treatments
#	----------------------------------------------------------------------------------------------
	field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'treatment_code'}
 

	field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'product_class_code'}
 

	field_configs[6] =  {:field_type => 'LabelField',
						:field_name => 'ripe_point_code'}
 
	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'size_code'}
    
    field_configs[8] =  {:field_type => 'LabelField',
						:field_name => 'cold_store_code'}
						
	field_configs[9] =  {:field_type => 'LabelField',
						:field_name => 'pc_code'}
						
	if ! is_view					
	 field_configs[10] =  {:field_type => 'DropDownField',
						:field_name => 'track_indicator_code',
						:settings => {:list => track_indicator_codes}}
    
      field_configs[11] =  {:field_type => 'DropDownField',
						:field_name => 'ca_cold_room_code',
						:settings => {:list => ca_cold_rooms}}
	
	else
	  field_configs[10] =  {:field_type => 'LabelField',
						:field_name => 'track_indicator_code'}
    
      field_configs[11] =  {:field_type => 'LabelField',
						:field_name => 'ca_cold_room_code'}
	
	end
	
						
	build_form(rmt_setup,field_configs,action,'rmt_setup',"save",true)

end
 


end
