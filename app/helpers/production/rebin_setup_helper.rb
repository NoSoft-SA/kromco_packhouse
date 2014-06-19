module Production::RebinSetupHelper
 
 
 def build_rebin_setup_form(rebin_setup,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	combos_js = gen_combos_clear_js_for_combos(["rebin_setup_label_code","rebin_setup_printer_format"])
	
	label_code_observer  = {:updated_field_id => "printer_format_cell",
					 :remote_method => 'label_code_combo_changed',
					 :on_completed_js => combos_js["rebin_setup_label_code"]}
	
	
	query = "SELECT 
             public.pack_material_products.pack_material_product_code
             FROM
             public.pack_material_sub_types
             INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
             INNER JOIN public.pack_material_products ON (public.pack_material_sub_types.id = public.pack_material_products.pack_material_sub_type_id)
             WHERE
            (public.pack_material_types.pack_material_type_code = 'RMU')"
	
	
	bin_products = PackMaterialProduct.find_by_sql(query).map{|b|b.pack_material_product_code}
	bin_products.unshift("<empty>")
   	                                 
	label_codes = Label.find_by_sql("Select distinct label_code from labels").map{|l|l.label_code}
	sizes = Size.find(:all).map{|l|l.size_code}
	
	printer_formats = nil
	if rebin_setup == nil||is_create_retry
		 printer_formats = ["Select a value from label_code"]
	elsif rebin_setup.rebin_label_setup
		#printer_formats = PrinterFormat.formats_for_label(rebin_setup.label_code).map{|l|l.printer_format_code}
	else
	 printer_formats = ["Select a value from label_code"]
	end
	
	ripe_point_codes = RipePoint.find_by_sql('select distinct ripe_point_code from ripe_points').map{|g|[g.ripe_point_code]}
	
	#tracking_indicators = TrackIndicator.find(:all).map{|t|t.track_indicator_code}
	rebin_setup.rmt_code = rebin_setup.production_schedule.rmt_setup.track_indicator_code if !rebin_setup.rmt_code
	
	#set the pc code if not set on the 'rebin_setup' record
	if rebin_setup == nil
	 rebin_setup = RebinSetup.new
	end
	
	if rebin_setup.pc_code == nil
	 pc_code = RmtSetup.find_by_production_schedule_id(session[:current_prod_schedule].id).pc_code
     rebin_setup.pc_code = pc_code
    end
    
    
    pc_codes = PcCode.find(:all).map{|p|p.pc_code}
    rebin_setup  = RebinSetup.new if !rebin_setup
    rebin_setup.label_code = "BIN1" if ! rebin_setup.label_code

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'rmt_product_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
						
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'product_class_code'}

	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'variety_output_description'}
	
	
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_from'}

	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_to'}
						
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[7] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}

	field_configs[8] = {:field_type => 'DropDownField',
						:field_name => 'product_code_pm_bintype',
						:settings => {:list => bin_products,:label_caption => "bin type"}}

	#field_configs[9] =  {:field_type => 'DropDownField',
	#					:field_name => 'label_code',
	#					:settings => {:list => label_codes}}
	#
#    
#    field_configs[7] =  {:field_type => 'DropDownField',
#						:field_name => 'printer_format',
#						:settings => {:list => printer_formats}}
    

#	field_configs[8] =  {:field_type => 'DropDownField',
#						:field_name => 'rmt_code',
#						:settings => {:list => tracking_indicators,:label_caption => "track indicators"}}
#						
#	field_configs[9] =  {:field_type => 'LabelField',
#						:field_name => 'rmt_description',:settings => {:label_caption => "track indicator description"}}
						
	field_configs[9] =  {:field_type => 'DropDownField',
						:field_name => 'ripe_point_code',
						:settings => {:list => ripe_point_codes}}
						
    field_configs[10] =  {:field_type => 'DropDownField',
						:field_name => 'size',
						:settings => {:list => sizes}}
						
	build_form(rebin_setup,field_configs,action,'rebin_setup',caption,is_edit)

end
 
  
 
 def build_label_seq_form(label)
 
  return if label.label_fields == nil||label.label_fields.length == 0
  @model = LabelSequence.new(label)
  
  htm = start_form_tag({:action=> "save_label_sequence"}, { :onSubmit => "show_element('ident_spinner');" })
  htm += "<table id = 'label_fields'>"
  index = 0
  js = "<script>"
  @model.fields.each do |field|
   #<a href = "javascript:nothing();" onclick = "select(this);">commodity</a>
    htm += "<row><td class = 'print_label_position_field'>" + field.keys[0] + "</td><td>"
    htm += "<a class = 'print_label_field' href = 'javascript:nothing();' onclick = 'select(this);'>" + field[field.keys[0]] + "</a>"
    htm += "</td></tr>"
    #labels[0] = "commodity";
    js += "labels[" + index.to_s + "]= '" + field[field.keys[0]] + "';"
    index += 1
    
  end
  
  js += "</script>"
  #add a couple of empty rows, then the up-down buttons, some more rows and then submit button
  htm += "<tr><td></td><tr><td></td></tr>"
  htm += "<tr><td></td><td>"
  htm += "<a href = 'javascript:nothing();' onclick = 'go_up(this);'><img src='/images/arrow_up.png' style='border-top-style: none; border-right-style: none; border-left-style: none; border-bottom-style: none' /></a>"
  htm += "<a href = 'javascript:nothing();' onclick = 'go_down(this);'><img src='/images/arrow_down.png' style='border-top-style: none; border-right-style: none; border-left-style: none; border-bottom-style: none' /></a>"
  htm += "</td></tr><tr><td></td><td></td><tr><td></td><td></td></tr><tr><td></td><td></td></tr><tr><td><td>"
  htm += hidden_field("label_sequence", "label_sequences_hidden_field",{:id => 'label_sequences_hidden_field'})
  htm += "<input type='submit' value='save sequence' />" 
  htm += image_tag('spinner.gif', :align => 'absmiddle', :border=> 0, :id=>"ident_spinner", :style=>"display: none;" )
  htm += "</table>" + end_form_tag
  return js + htm
 
 end
 
 def build_split_counts_form
  
  htm = start_form_tag({:action=> "save_size_counts"})
  htm += hidden_field("size_counts", "size_counts_txtranges",{:id => 'txtranges'})
  htm += "<input type='button' value='save' onclick = 'submit_ranges();'/>" 
  htm += image_tag('spinner.gif', :align => 'absmiddle', :border=> 0, :id=>"ident_spinner", :style=>"display: none;" )
  htm +=  end_form_tag
  
 end
 
 
 def build_rebin_setup_view(rebin_setup)

	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
    
    field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'rmt_product_code'}
					
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
							
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'product_class_code'}

	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'variety_output_description'}
	
	
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_from'}

	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_to'}

	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'product_code_pm_bintype'}


	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'label_code'}
    
    
    #:rmt_description,:rmt_code,:pc_code,:puc
    field_configs[8] =  {:field_type => 'LabelField',
						:field_name => 'rmt_description'}
						
	field_configs[9] =  {:field_type => 'LabelField',
						:field_name => 'rmt_code'}
						
	field_configs[10] =  {:field_type => 'LabelField',
						:field_name => 'ripe_point_code'}
						
    field_configs[11] =  {:field_type => 'LabelField',
						:field_name => 'size'}
	
	field_configs[12] =  {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[13] =  {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[14] =  {:field_type => 'LabelField',
						:field_name => 'rmt_product_code'}
						
	build_form(rebin_setup,field_configs,"view_paging_handler",'rebin_setup',"back")

end



 def build_rebin_setup_grid(data_set)

	column_configs = Array.new
	require File.dirname(__FILE__) + "/../../../app/helpers/production/rebin_setup_plugin.rb"

	column_configs[0] = {:field_type => 'text',:field_name => 'label_code',:col_width => 55}
	column_configs[1] = {:field_type => 'text',:field_name => 'product_class_code',:col_width => 55,:column_caption => 'class'}
	column_configs[2] = {:field_type => 'text',:field_name => 'variety_output_description',:col_width => 70,:column_caption => 'output_variety'}
	column_configs[3] = {:field_type => 'text',:field_name => 'product_code_pm_bintype',:col_width => 75,:column_caption => 'bin_type'}
	column_configs[4] = {:field_type => 'text',:field_name => 'standard_size_count_from',:col_width => 75,:column_caption => 'count_from'}
	column_configs[5] = {:field_type => 'text',:field_name => 'standard_size_count_to',:col_width => 75,:column_caption => 'count_to'}
	column_configs[6] = {:field_type => 'text',:field_name => 'size',:col_width => 65}
	column_configs[7] = {:field_type => 'text',:field_name => 'color_percentage',:col_width => 60,:column_caption => '% color'}
	column_configs[8] = {:field_type => 'text',:field_name => 'grade_code',:col_width => 65}
	column_configs[9] = {:field_type => 'text',:field_name => 'rmt_product_code',:col_width => 290}
	column_configs[10] = {:field_type => 'text',:field_name => 'ripe_point_code',:col_width => 60}
	column_configs[11] = {:field_type => 'text',:field_name => 'production_schedule.rmt_setup.track_indicator_code',:column_caption => "ti",:col_width => 60}
	
#	----------------------
#	define action columns
#	----------------------
	if @is_view == false
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit rebin_setup', :col_width => 55,
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_rebin_setup',
				:id_column => 'id'}}
		
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete rebin_setup', :col_width => 55,
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_rebin_setup',
				:id_column => 'id'}}
				
#		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'label fields sequence',
#			:settings => 
#				 {:link_text => 'label fields sequence',
#				:target_action => 'set_label_seq',
#				:id_column => 'id'}}
		
		
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'split counts', :col_width => 55 ,
			:settings => 
				 {:link_text => 'split counts',
				:target_action => 'split_counts',
				:id_column => 'id'}}
				
	else
	   column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view rebin_setup',:col_width => 55,
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_rebin_setup',
				:id_column => 'id'}}
	 
	end


 return get_data_grid(data_set,column_configs,RebinSetupPlugins::RebinSetupGridPlugin.new)
end

end
