
module Diagnostics::MidwareHelper

    def build_midware_grid(data_set, can_edit, can_delete)
        
        column_configs = Array.new
        
        data_set.each do |record|
               if record.short_description != nil
                   record.create_skip_ip
                   if record.short_description.include? "none"
                      record.create_carton_number
                   else
                      record.create_carton_number_for_nil
                   end
                   record.create_pallet_number
                   record.short_description = h(truncate(record.short_description, Globals.get_diagnostics_truncate_size()))
               else
                   record.create_skip_ip_for_nil
               end
               if record.error_description != nil
                  record.error_description = h(truncate(record.error_description, Globals.get_diagnostics_truncate_size()))
               end
               if record.stack_trace != nil
                  record.stack_trace = h(truncate(record.stack_trace, Globals.get_diagnostics_truncate_size()))
               end
               
        end
       
    	column_configs[0] = {:field_type => 'text',:field_name => 'error_description'}
    	column_configs[1] = {:field_type => 'text',:field_name => 'error_date_time'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'short_description'}
    	column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
    	column_configs[4] = {:field_type => 'text', :field_name => 'skip_ip'}
    	column_configs[5] = {:field_type => 'text', :field_name => 'line'}
    	column_configs[6] = {:field_type => 'text', :field_name => 'bay'}
        
        column_configs[7] = {:field_type => 'action',:field_name => 'view_details',
      	   :settings => 
      		 {:link_text =>'view details',
      		  :target_action => 'view_details',
      		  :id_column => 'id'}}
      		  
#        column_configs[8] = {:field_type => 'action',:field_name => 'view log',
#  			:settings => 
#  				 {:link_text => 'log',
#  				  :target_action => 'view_log',
#  				  :id_column => 'id'}}
#     
  		    column_configs[8]={:field_type=>'link_window',:field_name =>'view log',
          :settings =>
          {:id_column => 'id',
           :host_and_port =>request.host_with_port.to_s,
           :controller =>request.path_parameters['controller'].to_s ,
           :target_action => 'read_log_file',
           :link_text => 'log'}}
  				  
    	column_configs[9] = {:field_type => 'action', :field_name => 'view_carton', :settings =>{:target_action =>'view_carton', :id_column => 'id',:can_be_empty =>true}}
    	column_configs[10] = {:field_type => 'action', :field_name => 'view_pallet', :settings =>{:target_action =>'view_pallet', :id_column => 'id',:can_be_empty =>true}}
        #----------------------
        #define action columns
        #----------------------
           
        return get_data_grid(data_set,column_configs)
    end
    
    def view_midware_error_log(midware,action)
        
        field_configs = Array.new
        
        field_configs[0] =  {:field_type => 'LabelField',
  						:field_name => 'error_date_time'}
						
    	field_configs[1] =  {:field_type => 'LabelField',
    						:field_name => 'stack_trace'}
    				
     
    	field_configs[2] =  {:field_type => 'LabelField',
    						:field_name => 'short_description'}
    						
        field_configs[3] =  {:field_type => 'LabelField',
    						:field_name => 'error_description'}
    						
    	field_configs[4] =  {:field_type => 'LabelField',
    						:field_name => 'mw_type'}
    	
    	build_form(midware,field_configs,action,'midware_error_log',"back")
    end
    
    def view_carton_record(carton,action)
        
        field_configs = Array.new
        
        field_configs[0] =  {:field_type => 'LabelField',
  						:field_name => 'carton_number'}
						
    	field_configs[1] =  {:field_type => 'LabelField',
    						:field_name => 'erp_station'}
    				
     
    	field_configs[2] =  {:field_type => 'LabelField',
    						:field_name => 'commodity_code'}
    						
        field_configs[3] =  {:field_type => 'LabelField',
    						:field_name => 'carton_mark_code'}
    						
    	field_configs[4] =  {:field_type => 'LabelField',
    						:field_name => 'target_market_code'}
    						
    	field_configs[5] =  {:field_type => 'LabelField',
    						:field_name => 'variety_short_long'}
    						
    	field_configs[6] =  {:field_type => 'LabelField',
    						:field_name => 'fg_code_old'}
    						
    	field_configs[7] =  {:field_type => 'LabelField',
    						:field_name => 'inspection_type_code'}
    						
    	field_configs[8] =  {:field_type => 'LabelField',
    						:field_name => 'carton_label_code'}
    						
    	field_configs[9] =  {:field_type => 'LabelField',
    						:field_name => 'carton_pack_station_code'}
    						
    	field_configs[10] =  {:field_type => 'LabelField',
    						:field_name => 'order_number'}
    						
    	field_configs[11] =  {:field_type => 'LabelField',
    						:field_name => 'pack_date_time'}
    						
    	field_configs[12] =  {:field_type => 'LabelField',
    						:field_name => 'grade_code'}
    						
    	field_configs[13] =  {:field_type => 'LabelField',
    						:field_name => 'actual_size_count_code'}
    						
    	field_configs[14] =  {:field_type => 'LabelField',
    						:field_name => 'old_pack_code'}
    						
    	field_configs[15] =  {:field_type => 'LabelField',
    						:field_name => 'treatment_code'}
    						
    	field_configs[16] =  {:field_type => 'LabelField',
    						:field_name => 'product_class_code'}
    						
        field_configs[field_configs.length()] =  {:field_type => 'LabelField',
    						:field_name => 'pallet_id'}
    
        field_configs[field_configs.length()] =  {:field_type => 'LinkField',
    						:field_name => 'view pallet',
    						:settings => 
    						{:link_text => 'view pallet',
    						 :target_action => 'view_pallet_from_carton_form_palletizing',
    						 :id_column => 'pallet_id'
    						}}
    	
    	build_form(carton,field_configs,action,'carton',"back")
    end
    
    #***********Pallet's Cartons*****************
    def build_pallet_cartons_grid(carton,can_edit,can_delete)
        column_configs = Array.new
        
        column_configs[0] = {:field_type => 'text',:field_name => 'production_run_id'}
    	column_configs[1] = {:field_type => 'text',:field_name => 'pallet_id'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_label_station_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_number'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'erp_station'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'erp_pack_point'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'commodity_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_mark_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'target_market_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'variety_short_long'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_code_old'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'quarantine'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inspection_type_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_label_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_pack_station_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'order_number'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_date_time'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'actual_size_count_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'grade_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'old_pack_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'qc_status_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'treatment_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'chemical_status_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'product_class_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'erp_cultivar'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'track_indicator_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pc_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'cold_store_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'line_code'}
    	column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shift_code'}
    	column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'pallet_number', :settings =>{:target_action =>'view_pallet2', :id_column => 'pallet_number'}}
    	
    	return get_data_grid(carton,column_configs)
    end
    #*************End******************************
    
    
    def view_pallet_record(pallet,action)
        field_configs = Array.new
        
        field_configs[0] =  {:field_type => 'LabelField',
  						:field_name => 'pallet_number'}
						
    	field_configs[1] =  {:field_type => 'LabelField',
    						:field_name => 'fg_product_code'}
    				
     
    	field_configs[2] =  {:field_type => 'LabelField',
    						:field_name => 'build_status'}
    						
        field_configs[3] =  {:field_type => 'LabelField',
    						:field_name => 'oldest_pack_date_time'}
    						
    	field_configs[4] =  {:field_type => 'LabelField',
    						:field_name => 'size_count_code'}
    						
    	field_configs[5] =  {:field_type => 'LabelField',
    						:field_name => 'carton_mark_code'}
    						
    	field_configs[6] =  {:field_type => 'LabelField',
    						:field_name => 'target_market_code'}
    						
    	field_configs[7] =  {:field_type => 'LabelField',
    						:field_name => 'grade_code'}
    						
    	field_configs[8] =  {:field_type => 'LabelField',
    						:field_name => 'marketing_variety_code'}
    						
    	field_configs[9] =  {:field_type => 'LabelField',
    						:field_name => 'old_pack_code'}
    						
    	field_configs[10] =  {:field_type => 'LabelField',
    						:field_name => 'pallet_label_code'}
    						
    	field_configs[11] =  {:field_type => 'LabelField',
    						:field_name => 'qc_status_code'}
    						
    	field_configs[12] =  {:field_type => 'LabelField',
    						:field_name => 'carton_quantity_actual'}
    						
    	field_configs[13] =  {:field_type => 'LabelField',
    						:field_name => 'country_origin_code'}
    						
    	field_configs[14] =  {:field_type => 'LabelField',
    						:field_name => 'inventory_code'}
    						
    	field_configs[15] =  {:field_type => 'LabelField',
    						:field_name => 'pick_reference_code'}
    						
    	field_configs[16] =  {:field_type => 'LabelField',
    						:field_name => 'process_status'}
    						
    	field_configs[field_configs.length()] =  {:field_type => 'LinkField',
    						:field_name => 'view cartons',
    						:settings =>{:link_text => 'view cartons',
    						             :target_action => 'view_cartons',
    						             :id_column =>'id'}}
    	
    	build_form(pallet,field_configs,action,'pallet',"back")
    end
   
#*************************BIN TIPPING************************************
    def build_bintipping_grid(data_set, can_edit, can_delete)
      column_configs = Array.new
      #   puts data_set.class.name
        data_set.each do |record|
        
     #   puts record.private_methods
            if record.short_description == nil || record.short_description ==""
                record.create_bin_number_for_nil
            #    record.create_bin_id_for_nil
            else
                record.create_bin_number
             #   record.create_bin_id
                record.short_description = h(truncate(record.short_description, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.error_description != nil
                record.error_description = h(truncate(record.error_description, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.stack_trace != nil
                record.stack_trace = h(truncate(record.stack_trace, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.production_run_code!=nil
                record.create_line_code
            else
                record.create_line_code_for_nil
            end
         record.bin_id
           
                   end
        
        column_configs[0] = {:field_type => 'text',:field_name => 'error_description'}
    	column_configs[1] = {:field_type => 'text',:field_name => 'error_date_time'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'short_description'}
    	column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
    	column_configs[4] = {:field_type => 'text',:field_name => 'line_code'}
    	column_configs[5] = {:field_type => 'text',:field_name => 'production_run_code'}
    	
    	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view details',
      	   :settings => 
      		 {:link_text =>'detail',
      		  :target_action => 'view_bintipping_details',
      		  :id_column => 'id'}}
      		  
#        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view log',
#      	   :settings => 
#      		 {:link_text =>'log',
#      		  :target_action => 'view_bintipping_log',
#      		  :id_column => 'id'}}
#      
         
         column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view_bin', :settings =>{:target_action =>'view_bin', :id_column =>'bin_id'}}
         
         column_configs[column_configs.length()]={:field_type=>'link_window',:field_name =>'view log',
          :settings =>
          {:id_column => 'id',
           :host_and_port =>request.host_with_port.to_s,
           :controller =>request.path_parameters['controller'].to_s ,
           :target_action => 'read_log_file',
           :link_text => 'log'}}
           
#             column_configs[column_configs.length()]={:field_type=>'link_window',:field_name =>'bin_id',
#          :settings =>
#          {:id_column => 'bin_id',
#           :host_and_port =>request.host_with_port.to_s,
#           :controller =>request.path_parameters['controller'].to_s ,
#           :target_action => 'view_bin',
#           :link_text => 'view_bin'}}
           
#          column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view_bin', 
#          :settings =>
#          {:target_action =>'view_bin',
#          :link_text => 'view bin',
#           :id_column => 'bin_id'
#           
#           }}
#           
 
    	
    	return get_data_grid(data_set,column_configs)
    end
    
    
    def view_bintipping_details_form(midware,action)
        field_configs = Array.new
        
        field_configs[0] =  {:field_type => 'LabelField',
  						:field_name => 'error_date_time'}
						
    	field_configs[1] =  {:field_type => 'LabelField',
    						:field_name => 'stack_trace'}
    				
     
    	field_configs[2] =  {:field_type => 'LabelField',
    						:field_name => 'short_description'}
    						
        field_configs[3] =  {:field_type => 'LabelField',
    						:field_name => 'error_description'}
    						
    	field_configs[4] =  {:field_type => 'LabelField',
    						:field_name => 'mw_type'}
    	
    	build_form(midware,field_configs,action,'midware_error_log',"back")
    end
    
    
    def view_bin_form(bin_tipped,action)
        
        field_configs = Array.new
        
        field_configs[0] =  {:field_type => 'LabelField',
  						:field_name => 'bin_id'}
						
    	field_configs[1] =  {:field_type => 'LabelField',
    						:field_name => 'production_schedule_name'}
    				
     
    	field_configs[2] =  {:field_type => 'LabelField',
    						:field_name => 'production_run_code'}
    						
        field_configs[3] =  {:field_type => 'LabelField',
    						:field_name => 'line_code'}
    						
    	field_configs[4] =  {:field_type => 'LabelField',
    						:field_name => 'tipped_date_time'}
    						
        field_configs[5] =  {:field_type => 'LabelField',
    						:field_name => 'delivery_id'}
    						
    	field_configs[6] =  {:field_type => 'LabelField',
    						:field_name => 'weight'}
    						
    	field_configs[7] =  {:field_type => 'LabelField',
    						:field_name => 'class_description'}
    						
    	field_configs[8] =  {:field_type => 'LabelField',
    						:field_name => 'farm_code'}
    						
    	field_configs[9] =  {:field_type => 'LabelField',
    						:field_name => 'delivery_no'}
    						
    	field_configs[10] =  {:field_type => 'LabelField',
    						:field_name => 'track_indicator_code'}
    						
    	field_configs[11] =  {:field_type => 'LabelField',
    						:field_name => 'bin_receive_datetime'}
    						
    	field_configs[12] =  {:field_type => 'LabelField',
    						:field_name => 'tipped_in_reworks'}
    						
    						
        build_form(bin_tipped,field_configs,action,'bins_tipped',"back")
        
    end
    
#***********************END OF BIN TIPPING********************************

#***************************CARTON LABELING*******************************

def build_carton_labeling_grid(data_set, can_edit, can_delete)
    column_configs = Array.new
    
    data_set.each do |record|
        if record.short_description != nil
            record.create_station_code
            record.short_description = h(truncate(record.short_description, Globals.get_diagnostics_truncate_size()))
        else
            record.create_station_code_for_nil
        end
        
        if record.error_description != nil
            record.error_description = h(truncate(record.error_description, Globals.get_diagnostics_truncate_size()))
        end
        
        if record.stack_trace!=nil
            record.stack_trace = h(truncate(record.stack_trace, Globals.get_diagnostics_truncate_size()))
        end
        
        if record.production_run_code!=nil
            record.create_line_code
        else
            record.create_line_code_for_nil
        end
        
    end
    
    column_configs[0] = {:field_type => 'text',:field_name => 'error_description'}
  	column_configs[1] = {:field_type => 'text',:field_name => 'error_date_time'}
  	column_configs[2] = {:field_type => 'text',:field_name => 'short_description'}
  	column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
  	column_configs[4] = {:field_type => 'text',:field_name => 'line_code'}
  	column_configs[5] = {:field_type => 'text',:field_name => 'production_run_code'}
  	column_configs[6] = {:field_type => 'text',:field_name => 'station_code'}
  	
  	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view details',
      	   :settings => 
      		 {:link_text =>'detail',
      		  :target_action => 'view_carton_labeling_error_details',
      		  :id_column => 'id'}}
      
         column_configs[column_configs.length()]={:field_type=>'link_window',:field_name =>'view log',
          :settings =>
          {:id_column => 'id',
           :host_and_port =>request.host_with_port.to_s,
           :controller =>request.path_parameters['controller'].to_s ,
           :target_action => 'read_log_file',
           :link_text => 'log'}} 
      
      		  
#    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view log',
#  			:settings => 
#  				 {:link_text => 'log',
#  				  :target_action => 'view_carton_labeling_log',
#  				  :id_column => 'id'}}
  				  
  	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view carton setup',
  			:settings => 
  				 {:link_text => 'view carton setup',
  				  :target_action => 'view_carton_setup_details',
  				  :id_column => 'id'}}
  	
  	return get_data_grid(data_set,column_configs)
end

def view_carton_labeling_error_log(midware,action)
    field_configs = Array.new
        
    field_configs[0] =  {:field_type => 'LabelField',
					:field_name => 'error_date_time'}
				
	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'stack_trace'}
 
	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'short_description'}
						
    field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'error_description'}
						
	field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'mw_type'}
	
	build_form(midware,field_configs,action,'midware_error_log',"back")
end

def view_carton_setup_form(midware,action)
    field_configs = Array.new
        
    field_configs[0] =  {:field_type => 'LabelField',
					:field_name => 'production_schedule_code'}
				
	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'fg_product_code'}
 
	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'org'}
						
    field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'standard_size_count_value'}
						
	field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
    field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
						
	field_configs[6] =  {:field_type => 'LabelField',
						:field_name => 'order_number'}
						
	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'marketing_variety_code'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'product_class_code'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'fruit_sticker_code'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'treatment_code'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'carton_setup_code'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'labels_and_templates_created'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'order_quantity'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'trade_env_code'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'order_quantity_produced'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'last_update_date_time'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'commodity_code'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'treatment_type_code'}
						
    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'pack_order'}
	
	build_form(midware,field_configs,action,'carton_setup',"back")
end

#*******************************END***************************************

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                              BAD SCANS CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def build_bad_scans_grid(data_set, can_edit, can_delete)
    column_configs = Array.new
    
    data_set.each do |record|
       if record.short_description != nil
           record.create_bad_scans_skip
           record.create_bad_scans_bay
           record.create_bad_scans_carton_number
           #record.short_description = h(truncate(record.short_description, Globals.get_diagnostics_truncate_size()))
       else
           record.create_bad_scans_skip_for_nil
           record.create_bad_scans_bay_for_nil
           record.create_bad_scans_carton_number_for_nil
       end
               
    end
    
    column_configs[0] = {:field_type=>'text', :field_name=>'short_description'}
    column_configs[1] = {:field_type=>'text', :field_name=>'skip'}
    column_configs[2] = {:field_type=>'text', :field_name=>'bay'}
    column_configs[3] = {:field_type=>'text', :field_name=>'carton_number'}
    
    return get_data_grid(data_set,column_configs)
end

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                              END OF BAD SCANS CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                              PDT CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def build_pdt_grid(data_set,can_edit,can_delete)
    column_configs = Array.new
        
        data_set.each do |record|
            if record.short_description != nil
                record.short_description = h(truncate(record.short_description, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.error_description != nil
                record.error_description = h(truncate(record.error_description, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.stack_trace != nil
                record.stack_trace = h(truncate(record.stack_trace, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.production_run_code!=nil
                record.create_line_code
            else
                record.create_line_code_for_nil
            end
        end
        
        column_configs[0] = {:field_type => 'text',:field_name => 'error_description'}
    	column_configs[1] = {:field_type => 'text',:field_name => 'error_date_time'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'short_description'}
    	column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
    	column_configs[4] = {:field_type => 'text',:field_name => 'line_code'}
    	column_configs[5] = {:field_type => 'text',:field_name => 'production_run_code'}
    	
    	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view details',
      	   :settings => 
      		 {:link_text =>'detail',
      		  :target_action => 'view_pdt_details',
      		  :id_column => 'id'}}
    	
    	return get_data_grid(data_set,column_configs)
end

def view_pdt_details_form(pdt,action)
      field_configs = Array.new
        
      field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'error_date_time'}
					
      field_configs[1] =  {:field_type => 'LabelField',
    						:field_name => 'stack_trace'}
    				
     
      field_configs[2] =  {:field_type => 'LabelField',
    						:field_name => 'short_description'}
  						
      field_configs[3] =  {:field_type => 'LabelField',
  						:field_name => 'error_description'}
  						
  	  field_configs[4] =  {:field_type => 'LabelField',
  	 					:field_name => 'mw_type'}
  	
  	  build_form(pdt,field_configs,action,'midware_error_log',"back")
end

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                              END PDT CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                              REBIN LABELING CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def build_rebin_labeling_grid(data_set,can_edit,can_delete)
    column_configs = Array.new
        
        data_set.each do |record|
            if record.short_description != nil
                record.short_description = h(truncate(record.short_description, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.error_description != nil
                record.error_description = h(truncate(record.error_description, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.stack_trace != nil
                record.stack_trace = h(truncate(record.stack_trace, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.production_run_code!=nil
                record.create_line_code
            else
                record.create_line_code_for_nil
            end
        end
        
        column_configs[0] = {:field_type => 'text',:field_name => 'error_description'}
    	column_configs[1] = {:field_type => 'text',:field_name => 'error_date_time'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'short_description'}
    	column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
    	column_configs[4] = {:field_type => 'text',:field_name => 'line_code'}
    	column_configs[5] = {:field_type => 'text',:field_name => 'production_run_code'}
    	
    	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view details',
      	   :settings => 
      		 {:link_text =>'detail',
      		  :target_action => 'view_rebin_labeling_details',
      		  :id_column => 'id'}}
    	
    	return get_data_grid(data_set,column_configs)
end

def view_rebin_labeling_details_form(rebin,action)
      field_configs = Array.new
        
      field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'error_date_time'}
					
      field_configs[1] =  {:field_type => 'LabelField',
    						:field_name => 'stack_trace'}
    				
     
      field_configs[2] =  {:field_type => 'LabelField',
    						:field_name => 'short_description'}
  						
      field_configs[3] =  {:field_type => 'LabelField',
  						:field_name => 'error_description'}
  						
  	  field_configs[4] =  {:field_type => 'LabelField',
  	 					:field_name => 'mw_type'}
  	
  	  build_form(rebin,field_configs,action,'midware_error_log',"back")
end

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                              END REBIN LABELING CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                               ALL MIDWARE ERRORS CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def build_all_midware_grid(data_set,can_edit,can_delete)
    column_configs = Array.new
        
        data_set.each do |record|
            if record.short_description != nil
                record.short_description = h(truncate(record.short_description, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.error_description != nil
                record.error_description = h(truncate(record.error_description, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.stack_trace != nil
                record.stack_trace = h(truncate(record.stack_trace, Globals.get_diagnostics_truncate_size()))
            end
            
            if record.production_run_code!=nil
                record.create_line_code
            else
                record.create_line_code_for_nil
            end
        end
        
        column_configs[0] = {:field_type => 'text',:field_name => 'error_description'}
    	column_configs[1] = {:field_type => 'text',:field_name => 'error_date_time'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'short_description'}
    	column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
    	column_configs[4] = {:field_type => 'text',:field_name => 'line_code'}
    	column_configs[5] = {:field_type => 'text',:field_name => 'production_run_code'}
    	
    	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view details',
      	   :settings => 
      		 {:link_text =>'detail',
      		  :target_action => 'view_all_midware_details',
      		  :id_column => 'id'}}
    	
    	return get_data_grid(data_set,column_configs)
end


def view_all_midware_details_form(all_midware,action)
    field_configs = Array.new
        
      field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'error_date_time'}
					
      field_configs[1] =  {:field_type => 'LabelField',
    						:field_name => 'stack_trace'}
    				
     
      field_configs[2] =  {:field_type => 'LabelField',
    						:field_name => 'short_description'}
  						
      field_configs[3] =  {:field_type => 'LabelField',
  						:field_name => 'error_description'}
  						
  	  field_configs[4] =  {:field_type => 'LabelField',
  	 					:field_name => 'mw_type'}
  	
  	  build_form(all_midware,field_configs,action,'midware_error_log',"back")
end

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                               END OF ALL MIDWARE ERRORS CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

end