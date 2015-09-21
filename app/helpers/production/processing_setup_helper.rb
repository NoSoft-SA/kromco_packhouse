module Production::ProcessingSetupHelper
 
 def build_pallet_criterium_form(pallet_criterium,action,caption,is_edit = nil,is_create_retry = nil,is_view = nil)


   action = nil if is_view == true
   
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new


	field_configs[0] = {:field_type => 'CheckBox',
						:field_name => 'target_market_code'}

	field_configs[1] = {:field_type => 'CheckBox',
						:field_name => 'inventory_code'}

	field_configs[2] = {:field_type => 'CheckBox',
						:field_name => 'mark_code'}

	field_configs[3] = {:field_type => 'CheckBox',
						:field_name => 'sell_by_code'}

	field_configs[4] = {:field_type => 'CheckBox',
						:field_name => 'farm_code'}
						
	field_configs[5] = {:field_type => 'CheckBox',
						:field_name => 'units_per_carton'}

	build_form(pallet_criterium,field_configs,action,'pallet_criteria_setup',caption,is_edit)

end
 
 def build_output_tracking_indicator_form(rmt_setup)
   
    tracking_indicators = TrackIndicator.find(:all,:order => "track_indicator_code").map{|t|t.track_indicator_code}
    
    
    if  rmt_setup.output_track_indicator_code
      rmt_setup.track_indicator_description = TrackIndicator.find_by_track_indicator_code(rmt_setup.output_track_indicator_code).description
    end
   
   
    field_configs = Array.new


	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'output_track_indicator_code',
						:settings => {:list => tracking_indicators}}
						
	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'track_indicator_description'}

	build_form(rmt_setup,field_configs,'update_output_tracking_indicator','rmt_setup','save',true)
 
 
 end
 
 
 
 def build_processing_setup_view(processing_setup)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	

	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_from'}

	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_to'}

	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}


	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'variety_output_description'}

 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (product_class_id) on related table: product_classes
#	----------------------------------------------------------------------------------------------
	field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'product_class_code'}
 
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (grade_id) on related table: grades
#	-----------------------------------------------------------------------------------------------------
	field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'grade_code'}

 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	field_configs[6] =  {:field_type => 'LabelField',
						:field_name => 'handling_product_code'}
 

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pack_material_product_id) on related table: pack_material_products
#	----------------------------------------------------------------------------------------------
	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'pack_material_type_code'}
 
	field_configs[8] =  {:field_type => 'LabelField',
						:field_name => 'pack_material_sub_type_code'}
 
	field_configs[9] =  {:field_type => 'LabelField',
						:field_name => 'pack_material_product_code'}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (treatment_id) on related table: treatments
#	----------------------------------------------------------------------------------------------
	field_configs[10] =  {:field_type => 'LabelField',
						:field_name => 'treatment_code'}
 
	build_form(processing_setup,field_configs,"view_paging_handler",'processing_setup',"back")

end
 
 def build_select_org_form(orgs_list,action,caption)
 
    field_configs = Array.new
	
	field_configs[0] = {:field_type => 'DropDownField',
						:field_name => 'trade_env_code',
						:settings => {:list => orgs_list}}
 
    build_form(nil,field_configs,action,'marketing_orgs',caption,nil,nil,nil,true)
 
 end
 
 
 def build_processing_setup_form(processing_setup,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	
	handling_js = "\n img = document.getElementById('img_processing_setup_handling_product_code');"
	handling_js += "\n if(img != null)img.style.display = 'none';"
					 
	handling_observer  = {:updated_field_id => "ajax_distributor_cell",
					 :remote_method => 'handling_code_changed',
					 :on_completed_js => handling_js}
	
	session[:processing_setup_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: pack_material_products
	
	
	#Observers for combos representing the key fields of fkey table: pack_material_product_id
	grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map{|g|[g.grade_code]}
	grade_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: handling_products
	
	combos_js_for_handling_products = gen_combos_clear_js_for_combos(["processing_setup_handling_product_code","processing_setup_standard_size_count_code"])
	#Observers for combos representing the key fields of fkey table: handling_product_id
	
	treatment_codes = "<empty>"
	if processing_setup && !is_create_retry
	 if processing_setup.handling_product_type_code.upcase == "PACK"
	   treatment_codes = Treatment.find_by_sql("select distinct treatment_code from treatments where treatment_type_code = 'PACKHOUSE'").map{|g|[g.treatment_code]}
	 else
	   treatment_codes = Treatment.find_by_sql("select distinct treatment_code from treatments where treatment_type_code = 'PACKHOUSE' ").map{|g|[g.treatment_code]}
	 end
	end
	
	product_class_codes = ProductClass.find_by_sql('select distinct product_class_code from product_classes').map{|g|[g.product_class_code]}
	product_class_codes.unshift("<empty>")
	
	
	pack_material_product_codes = nil 
 
	pack_material_type_codes = ProcessingSetup.get_all_pack_material_type_codes
	
	pack_material_type_codes.unshift "<empty>"
	
	pack_material_product_codes = ["Select a handling_product"]
	
	if processing_setup && processing_setup.handling_product
		if processing_setup.handling_product.handling_product_type_code.upcase == "REBIN"
		  pack_material_product_codes = ProcessingSetup.pack_material_product_codes_for_pack_material_type_code("RMU")
	    else
	      pack_material_product_codes = ProcessingSetup.pack_material_product_codes_for_pack_material_sub_type_code_and_pack_material_type_code("FRUIT","LB")
	    end
	end
	
#	combo lists for table: handling_products
    sizes = Size.find_all_by_commodity_code(@commodity_code).map{|l|l.size_code}
    #sizes.unshift "<empty>"

	handling_product_codes = nil 
	standard_size_count_codes = StandardSizeCount.counts_by_commodity(@commodity_code)
    standard_size_count_codes.push(-1)
	handling_product_codes = ProcessingSetup.get_all_handling_product_codes
	 
	output_varieties = nil
	if RmtSetup.is_orchard_run_rmt_product(session[:current_prod_schedule].id)
	 output_varieties = Variety.outputs_for_input(session[:current_prod_schedule].id)
	else
	 output_varieties = Variety.all_output_varieties_for_schedule(session[:current_prod_schedule].id)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
    if is_edit #&& processing_setup.handling_product.handling_product_type_code.upcase == "PACK"
       field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_from'}

	   field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_to'}
    else
	   field_configs[0] = {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_from',
						:settings => {:list => standard_size_count_codes}}

	   field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_to',
						:settings => {:list => standard_size_count_codes}}
    end
	

	field_configs[2] = {:field_type => 'DropDownField',
						:field_name => 'variety_output_description',
						:settings => {:list => output_varieties}}

 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (product_class_id) on related table: product_classes
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'product_class_code',
						:settings => {:list => product_class_codes}}
 
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (grade_id) on related table: grades
#	-----------------------------------------------------------------------------------------------------
    if processing_setup && processing_setup.production_schedule.production_schedule_status_code == "re_opened"
       
       field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	   field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'grade_code'}
    

    else
   
      field_configs[4] = {:field_type => 'TextField',
						:field_name => 'color_percentage'}
						
	  field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grade_codes}}
    end
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	if !processing_setup||is_create_retry
	  field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'handling_product_code',
						:settings => {:list => handling_product_codes},
						:observer => handling_observer}
	else
	 field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'handling_product_code'}
	
	end
 
     field_configs[7] = {:field_type => 'LabelField',
						:field_name => 'handling_product_type_code'}

	field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'pack_material_product_code',
						:settings => {:list => pack_material_product_codes}}
   
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (treatment_id) on related table: treatments
#	----------------------------------------------------------------------------------------------
	field_configs[9] = {:field_type => 'LabelField',
						:field_name => 'treatment_type_code'}
	
	field_configs[10] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_code',
						:settings => {:list => treatment_codes}}
	
	field_configs[11] =  {:field_type => 'DropDownField',
						:field_name => 'size',
						:settings => {:list => sizes}}
						
	field_configs[12] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}
						
 
	build_form(processing_setup,field_configs,action,'processing_setup',caption,is_edit)

end
 
 
 def build_processing_setup_search_form(processing_setup,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:processing_setup_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
	production_schedule_codes = ProcessingSetup.find_by_sql('select distinct production_schedule_code from processing_setups').map{|g|[g.production_schedule_code]}
	production_schedule_codes.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'production_schedule_code',
						:settings => {:list => production_schedule_codes}}

	build_form(processing_setup,field_configs,action,'processing_setup',caption,false)

end



 def build_processing_setup_grid(data_set)
 
   #require File.dirname(__FILE__) + "/../../../app/helpers/production/procc_setup_plugin.rb"

	column_configs = Array.new

	column_configs[0] = {:field_type => 'text',:field_name => 'handling_product_type_code',:col_width => 62,:column_caption => 'handling_type'}
	column_configs[1] = {:field_type => 'text',:field_name => 'standard_size_count_from',:col_width => 75,:column_caption => 'count_from'}
	column_configs[2] = {:field_type => 'text',:field_name => 'standard_size_count_to',:col_width => 75,:column_caption => 'count_to'}
	column_configs[3] = {:field_type => 'text',:field_name => 'product_class_code',:col_width => 55,:column_caption => 'class'}
	column_configs[4] = {:field_type => 'text',:field_name => 'grade_code',:col_width => 55}
	column_configs[5] = {:field_type => 'text',:field_name => 'handling_product_code',:col_width => 80}
	column_configs[6] = {:field_type => 'text',:field_name => 'color_percentage',:col_width => 55,:column_caption => '% color'}
	column_configs[7] = {:field_type => 'text',:field_name => 'variety_output_description',:col_width => 85,:column_caption => 'output_variety'}
	column_configs[8] = {:field_type => 'text',:field_name => 'treatment_code',:col_width => 95}
	column_configs[9] = {:field_type => 'text',:field_name => 'pack_material_product_code',:col_width => 90}
#	----------------------
#	define action columns
#	----------------------
	if @is_view == false
	 
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit processing_setup', :col_width => 55,
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_processing_setup',
				:id_column => 'id'}}
	
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete processing_setup', :col_width => 55,
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_processing_setup',
				:id_column => 'id'}}
	
  else
    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view processing_setup', :col_width => 55,
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_processing_setup',
				:id_column => 'id'}}
  end
	
 return get_data_grid(data_set,column_configs,MesScada::GridPlugins::Production::ProcessingSetupGridPlugin.new)
end

end
