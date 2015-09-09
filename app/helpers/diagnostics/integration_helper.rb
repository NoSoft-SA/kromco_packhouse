
module Diagnostics::IntegrationHelper

def build_outbox_enties_grid(data_set,can_edit=nil,can_delete=nil,is_for_rmt_setup = nil,can_setup = nil)

	column_configs = Array.new
	session[:object_type] = Hash.new if !session[:object_type]
	session[:type_code] = Hash.new if !session[:type_code]
	data_set.each do |rec|
	  rec.set_data
	  rec.data = h(truncate(rec.data,50))
	  session[:type_code].store(rec.id.to_s, rec.type_code)
	  session[:object_type].store(rec.record_id.to_s, rec.object_type)
	end
	
	column_configs[0] = {:field_type => 'text',:field_name => 'data'}
	column_configs[1] = {:field_type => 'text',:field_name => 'created_on'}
	column_configs[2] = {:field_type => 'text',:field_name => 'type_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'object_type'}
	column_configs[4] = {:field_type => 'text',:field_name => 'process_status'}
	
	
#	----------------------
#	define action columns
#	----------------------	
	column_configs[5] = {:field_type => 'action',:field_name => 'object_id',
      	   :settings => 
      		 {:target_action => 'view_record',
      		  :id_column => 'record_id'}}
      		  #:id_column => 'joined_field'}}
    
    column_configs[6] = {:field_type => 'action',:field_name => 'record_map',
      	   :settings => 
      		 {:link_text => 'view_record_hash',
      		  :target_action => 'view_record_hash',
      		  :id_column => 'record_id'}}
      	
    column_configs[7] = {:field_type => 'action',:field_name => 'rails error',
      	   :settings => 
      		 {:link_text => 'logged_error',
      		  :target_action => 'view_logged_error',
      		  :id_column => 'id'}}
      		  
      		  
    column_configs[8] = {:field_type => 'text',:field_name => 'id'}

   column_configs[8] = {:field_type => 'text',:field_name => 'id'}
	
 return get_data_grid(data_set,column_configs)
end

def build_pallet_cartons_grid(data_set,can_edit=nil,can_delete=nil,is_for_rmt_setup = nil,can_setup = nil)
   column_configs = Array.new
  
   i = 0
     for column in Carton.content_columns 
         field_name = column.name
         column_configs[i] =  {:field_type => 'text',
  						:field_name => field_name}
  	   i+=1
     end
  
   return get_data_grid(data_set,column_configs)
end

def build_pallet_view(pallet,action)
        field_configs = Array.new
        
    i = 0
     for column in Pallet.content_columns 
       
         field_name = column.name
         field_configs[i] =  {:field_type => 'LabelField',
  						:field_name => field_name}
  	   i+=1
  	   
     end
  
      
#	----------------------
#	define action fields
#	----------------------	
  if pallet.respond_to?('pallet_template_id')
  		 field_configs[i] = {:field_type => 'LinkField',:field_name => 'pallet_template_id',
      	   :settings => 
      		 {:css_class => "green_label_field",
      		 :link_text => 'view_pallet_template',
      		 :target_action => 'view_pallet_template',
      		  :id_column => 'pallet_template_id'}}
     i+=1
  end

  if pallet.respond_to?('production_run_id')
        field_configs[i] = {:field_type => 'LinkField',:field_name => 'production_run_id',
      	   :settings => 
      		 {:link_text => 'view_production_run',
      		  :target_action => 'view_run',
      		  :id_column => 'production_run_id'}}
     i+=1
  end

  if pallet.respond_to?("pallet_number")
        field_configs[i] = {:field_type => 'LinkField',:field_name => 'pallet_number',
      	   :settings => 
      		 {:link_text => 'view_pallet_cartons',
      		 :target_action => 'view_pallet_cartons',
      		  :id_column => 'pallet_number'}}
  end    		  
    	build_form(pallet,field_configs,action,'pallet',"back",nil,nil,nil,true)
end

    
def build_pallet_template_view(pallet_template,action=nil)

        field_configs = Array.new
        
        i = 0
        for column in PalletTemplate.content_columns 
          field_name = column.name
          field_configs[i] =  {:field_type => 'LabelField',
  		             		   :field_name => field_name}
  	     i+=1
       end
       
#	----------------------
#	define action fields
#	----------------------	
  		field_configs[i] = {:field_type => 'LinkField',:field_name => 'carton_setup_id',
      	   :settings => 
      		 {:link_text => 'view carton_setup',
      		  :target_action => 'view_carton_setup',
      		  :id_column => 'carton_setup_id'}}
       
       build_form(pallet_template,field_configs,action,'pallet_template',"back",nil,nil,nil,true)
end

def build_ppecb_inspection_view(ppecb_inspection,action)

    field_configs = Array.new
        
        i = 0
        for column in PpecbInspection.content_columns 
          field_name = column.name
          field_configs[i] =  {:field_type => 'LabelField',
  		             		   :field_name => field_name}
  	     i+=1
       end
     
     build_form(ppecb_inspection,field_configs,action,'ppecb_inspection',"back")
end

def build_rebin_view(rebin,action)
   field_configs = Array.new
        
    i = 0
     for attr in rebin.attribute_names()
         field_name = rebin.attribute_names[i]
         field_configs[i] =  {:field_type => 'LabelField',
  						:field_name => field_name}
  	   i+=1
     end
     
     field_configs[i] = {:field_type => 'LinkField',:field_name => 'production_run_id',
      	   :settings => 
      		 {:link_text => 'view production run',
      		 :target_action => 'view_run',
      		  :id_column => 'production_run_id'}}
     
     build_form(rebin,field_configs,action,'rebin',"back")
end

def build_bin_view(bin,action)
   field_configs = Array.new
        
    i = 0
     for attr in bin.attribute_names()
         field_name = bin.attribute_names[i]
         field_configs[i] =  {:field_type => 'LabelField',
  						:field_name => field_name}
  	   i+=1
     end
     
     field_configs[i] = {:field_type => 'LinkField',:field_name => 'production_run_code',
      	   :settings => 
      		 {:link_text => "view procution run", 
      		  :target_action => 'view_production_run',
      		  :id_column => 'production_run_code'}}
     
     build_form(bin,field_configs,action,'bin',"back")
end

def build_carton_view(carton,action)

      field_configs = Array.new
        
    i = 0
     for column in Carton.content_columns 
         field_name = column.name
         field_configs[i] =  {:field_type => 'LabelField',
  						:field_name => field_name}
  	   i+=1
     end
     
     
     field_configs[i] = {:field_type => 'LinkField',
                         :field_name => 'pallet_number',
      	                 :settings => 
      		               {:link_text => "view pallet",
      		                :target_action => 'view_pallet',
      		                :id_column => 'pallet_number'}}
      		                
     field_configs[i+1] = {:field_type => 'LinkField',
                         :field_name => 'production_run_id',
      	                 :settings => 
      		               {:link_text => "view procution run",
      		                :target_action => 'view_run',
      		                :id_column => 'production_run_id'}}
      		                
     field_configs[i+2] = {:field_type => 'LinkField',
                         :field_name => 'carton_template_id',
      	                 :settings => 
      		               {:link_text => 'view carton_setup',
      		                :target_action => 'view_carton_setup',
      		                :id_column => 'carton_template_id'}}
      		               
     field_configs[i+3] = {:field_type => 'LinkField',
                         :field_name => 'carton_template_id',
      	                 :settings => 
      		               {:link_text => 'view carton_label_setup',
      		               :target_action => 'view_carton_label_setup',
      		                :id_column => 'carton_template_id'}}
     
     build_form(carton,field_configs,action,'carton',"back",nil,nil,nil,true)
end

def carton_label_setup_view(carton_label_setup,action)
    field_configs = Array.new
        
    i = 0
     for column in CartonLabelSetup.content_columns 
         field_name = column.name
         field_configs[i] =  {:field_type => 'LabelField',
  						:field_name => field_name}
  	   i+=1
     end
     
     build_form(carton_label_setup,field_configs,action,'carton_label_setup',"back")
end

def build_rails_error_view(rails_error,action)

     field_configs = Array.new
        
    i = 0
     for column in RailsError.content_columns 
         field_name = column.name
         field_configs[i] =  {:field_type => 'LabelField',
  						:field_name => field_name}
  	   i+=1
     end
     
     build_form(rails_error,field_configs,action,'rails_error',"back")
end

#$$$$$$$$$$$$$$$$$$$$$$$$$$
def carton_setup_view(carton_setup,action)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

     require File.dirname(__FILE__) + "/../../../app/helpers/production/carton_setup_plugin.rb"

	 field_configs = Array.new
	 
	 
	 
	 field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
     
     field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'carton_setup_code'}
 

	 field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'org'}

	 field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_value'}

	 field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	 field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}

	 field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}

	 field_configs[7] = {:field_type => 'LabelField',
						:field_name => 'order_number'}
						
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'order_quantity'}
						
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'order_quantity_produced'}
	
	 if carton_setup.retail_item_setup					
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'retail_item_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_retail_item_setup',
				:id_column => 'id'}}
	
	 end
	
	 if carton_setup.retail_unit_setup
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'retail_unit_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_retail_unit_setup',
				:id_column => 'id'}}
				
	 end
	
	if carton_setup.trade_unit_setup			
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'trade_unit_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_trade_unit_setup',
				:id_column => 'id'}}
    end
	
	if carton_setup.fg_setup			
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'fg_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_fg_setup',
				:id_column => 'id'}}
	end
	if carton_setup.pallet_setup			
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'pallet_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_pallet_setup',
				:id_column => 'id'}}
    end
    
    if carton_setup.palletizing_criterium
	  field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'palletizing_criteria',
			:settings => 
				 {:link_text => 'view_pallet_criteria',
				:target_action => 'palletizing_criteria_setup',
				:id_column => 'id'}}
    end
    
	# build_form(carton_setup,field_configs,action,'view_pallet_template',"back",nil,nil,nil,nil,MesScada::GridPlugins::Production::CartonSetupFormPlugin.new)
   build_form(carton_setup,field_configs,action,'view_pallet_template',"back",nil,nil,nil,nil,CartonSetupPlugins::CartonSetupFormPlugin.new)

end
#$$$$$$$$$$$$$$$$$


#..........................................................................................
#........................CODE FROM THE INTEGRATION CONTOLLER...............................
#..........................................................................................
#..........................................................................................
#..........................................................................................

    def build_missing_flows_grid(data_set,can_edit,can_delete)
        column_configs = Array.new
        
        data_set.each do |record|
            if record.short_description!=nil
                if record.short_description.include? "Integration record of type"
                    record.create_flow
                    record.create_object_id
               
                    record.create_missing
                    record.create_field_flowing
                else
                    record.create_flow_for_nil
                    record.create_object_id_for_nil
                    record.create_missing_for_nil
                    record.create_field_flowing_for_nil
                end
                record.short_description = h(truncate(record.short_description, Globals.get_diagnostics_truncate_size()))
            else
                record.create_flow_for_nil
                record.create_object_id_for_nil
                record.create_missing_for_nil
                record.create_field_flowing_for_nil
            end
            
            if record.error_description!=nil
                record.error_description = h(truncate(record.error_description, Globals.get_diagnostics_truncate_size()))
            end
        end
        
        column_configs[0] = {:field_type =>'text', :field_name =>'error_date_time'}
        column_configs[column_configs.length()] = {:field_type =>'text', :field_name =>'error_description'}
        column_configs[column_configs.length()] = {:field_type =>'text', :field_name =>'flow'}
        column_configs[column_configs.length()] = {:field_type =>'text', :field_name =>'object_id'}
        column_configs[column_configs.length()] = {:field_type =>'text', :field_name =>'short_description'}
        
        column_configs[column_configs.length()] = {:field_type =>'action', :field_name =>'detail',
                    :settings =>{:link_text =>'view',
                                 :target_action =>'view_details',
                                 :id_column =>'id'}}
                                 
        column_configs[column_configs.length()] = {:field_type =>'text', :field_name =>'missing'}
        
        column_configs[column_configs.length()] = {:field_type =>'action', :field_name =>'new_outbox_entry_record', :settings =>{:target_action =>'create_flow_details', :id_column =>'calc_id'}}
        
        session[:result_set] = data_set
        
        return get_data_grid(data_set,column_configs)
    end
    
    def view_missing_flows_error_log_form(midware,action)
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
#::::::::::::::::::::::::::::::::::::: END OF HAPPYMORE'S CODE ::::::::::::::::::::::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
end
