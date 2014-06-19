module Tools::SizerTemplateHelper
 
 
 def build_sizer_template_form(sizer_template,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	
	require File.dirname(__FILE__) + "/../../../app/helpers/tools/sizer_template_plugin.rb"
	
	session[:sizer_template_form]= Hash.new
	farm_group_codes = FarmGroup.find_by_sql('select distinct farm_group_code from farm_groups').map{|g|[g.farm_group_code]}
	farm_group_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: rmt_varieties
	combos_js_for_rmt_varieties = gen_combos_clear_js_for_combos(["sizer_template_commodity_group_code","sizer_template_commodity_code","sizer_template_rmt_variety_code"])
	#Observers for combos representing the key fields of fkey table: rmt_variety_id
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'sizer_template_commodity_group_code_changed',
					 :on_completed_js => combos_js_for_rmt_varieties ["sizer_template_commodity_group_code"]}

	session[:sizer_template_form][:commodity_group_code_observer] = commodity_group_code_observer

	commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
					 :remote_method => 'sizer_template_commodity_code_changed',
					 :on_completed_js => combos_js_for_rmt_varieties ["sizer_template_commodity_code"]}

	session[:sizer_template_form][:commodity_code_observer] = commodity_code_observer

#	combo lists for table: rmt_varieties

	commodity_group_codes = nil 
	commodity_codes = nil 
	rmt_variety_codes = nil 
 
	commodity_group_codes = SizerTemplate.get_all_commodity_group_codes
	if sizer_template == nil||is_create_retry
		 commodity_codes = ["Select a value from commodity_group_code"]
		 rmt_variety_codes = ["Select a value from commodity_code"]
	else
		commodity_codes = SizerTemplate.commodity_codes_for_commodity_group_code(sizer_template.rmt_variety.commodity_group_code)
		rmt_variety_codes = SizerTemplate.rmt_variety_codes_for_commodity_code_and_commodity_group_code(sizer_template.rmt_variety.commodity_code, sizer_template.rmt_variety.commodity_group_code)
	end
	
	line_config_codes = LineConfig.find_by_sql("Select distinct line_config_code from line_configs").map{|l|[l.line_config_code]}
	size_codes = Size.find_by_sql("Select distinct size_code from sizes").map{|s|s.size_code}
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'template_name'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (rmt_variety_id) on related table: rmt_varieties
#	----------------------------------------------------------------------------------------------
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_code',
						:settings => {:list => rmt_variety_codes}}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'fruit_size',
						:settings => {:list => size_codes}}
 

	field_configs[5] = {:field_type => 'TextField',
						:field_name => 'color_sorting'}
						
    field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'line_config_code',
						:settings => {:list => line_config_codes}}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (farm_group_id) on related table: farm_groups
#	----------------------------------------------------------------------------------------------
	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'farm_group_code',
						:settings => {:list => farm_group_codes}}
 
   if is_edit
      field_configs[8] = {:field_type => 'LinkField',:field_name => 'pack_groups',
			:settings => 
				 {:link_text => 'list',
				:target_action => 'list_pack_groups',
				:id_column => 'id'}}
	
       field_configs[9] = {:field_type => 'LinkField',:field_name => 'new_pack_group',
			:settings => 
				 {:link_text => 'create_new',
				:target_action => 'new_pack_group',
				:id_column => 'id'}}			
	end			
	build_form(sizer_template,field_configs,action,'sizer_template',caption,is_edit,nil,nil,nil,SizerTemplatePlugins::SizerTemplateFormPlugin.new)
 
end
 
 
 def build_sizer_template_search_form(sizer_template,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:sizer_template_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["sizer_template_commodity_code","sizer_template_rmt_variety_code","sizer_template_fruit_size","sizer_template_color_sorting","sizer_template_line_code"])
	#Observers for search combos
	commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
					 :remote_method => 'sizer_template_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["sizer_template_commodity_code"]}

	session[:sizer_template_search_form][:commodity_code_observer] = commodity_code_observer

	rmt_variety_code_observer  = {:updated_field_id => "fruit_size_cell",
					 :remote_method => 'sizer_template_rmt_variety_code_search_combo_changed',
					 :on_completed_js => search_combos_js["sizer_template_rmt_variety_code"]}

	session[:sizer_template_search_form][:rmt_variety_code_observer] = rmt_variety_code_observer

	fruit_size_observer  = {:updated_field_id => "color_sorting_cell",
					 :remote_method => 'sizer_template_fruit_size_search_combo_changed',
					 :on_completed_js => search_combos_js["sizer_template_fruit_size"]}

	session[:sizer_template_search_form][:fruit_size_observer] = fruit_size_observer

	color_sorting_observer  = {:updated_field_id => "line_code_cell",
					 :remote_method => 'sizer_template_color_sorting_search_combo_changed',
					 :on_completed_js => search_combos_js["sizer_template_color_sorting"]}

	session[:sizer_template_search_form][:color_sorting_observer] = color_sorting_observer

 
	commodity_codes = SizerTemplate.find_by_sql('select distinct commodity_code from sizer_templates').map{|g|[g.commodity_code]}
	commodity_codes.unshift("<empty>")
	if is_flat_search
		rmt_variety_codes = SizerTemplate.find_by_sql('select distinct rmt_variety_code from sizer_templates').map{|g|[g.rmt_variety_code]}
		rmt_variety_codes.unshift("<empty>")
		fruit_sizes = SizerTemplate.find_by_sql('select distinct fruit_size from sizer_templates').map{|g|[g.fruit_size]}
		fruit_sizes.unshift("<empty>")
		color_sortings = SizerTemplate.find_by_sql('select distinct color_sorting from sizer_templates').map{|g|[g.color_sorting]}
		color_sortings.unshift("<empty>")
		line_config_codes = SizerTemplate.find_by_sql('select distinct line_config_code from sizer_templates').map{|g|[g.line_config_code]}
		line_config_codes.unshift("<empty>")
		commodity_code_observer = nil
		rmt_variety_code_observer = nil
		fruit_size_observer = nil
		color_sorting_observer = nil
	else
		 rmt_variety_codes = ["Select a value from commodity_code"]
		 fruit_sizes = ["Select a value from rmt_variety_code"]
		 color_sortings = ["Select a value from fruit_size"]
		 line_config_codes = ["Select a value from color_sorting"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_code',
						:settings => {:list => rmt_variety_codes},
						:observer => rmt_variety_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'fruit_size',
						:settings => {:list => fruit_sizes},
						:observer => fruit_size_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'color_sorting',
						:settings => {:list => color_sortings},
						:observer => color_sorting_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'line_config_code',
						:settings => {:list => line_config_codes}}
 
	build_form(sizer_template,field_configs,action,'sizer_template',caption,false)

end


 def build_sizer_template_grid(data_set,can_edit,can_delete,apply_template_link = nil,save_to_template_link = nil)
    
     require File.dirname(__FILE__) + "/../../../app/helpers/tools/sizer_template_plugin.rb"
    
	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'template_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'rmt_variety_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'farm_group_code'}
	column_configs[4] = {:field_type => 'text',:field_name => 'commodity_group_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'fruit_size'}
	column_configs[6] = {:field_type => 'text',:field_name => 'color_sorting'}
	column_configs[7] = {:field_type => 'text',:field_name => 'line_config_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit && !apply_template_link
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit sizer_template',
			:settings => 
				 {:image => 'edit',
				:target_action => 'edit_sizer_template',
				:id_column => 'id'}}
	end

	if can_delete && !apply_template_link
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete sizer_template',
			:settings => 
				 {:image => 'delete',
				:target_action => 'delete_sizer_template',
				:id_column => 'id'}}
	end
	
	
	if apply_template_link
	   column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'apply sizer_template',
			:settings => 
				 {:link_text => 'apply',
				:target_action => 'apply_sizer_template',
				:id_column => 'id'}}
	
	
	end
	
	if save_to_template_link
	   column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'save_to_template',
			:settings => 
				 {:image => 'save_to_template',
				:target_action => 'save_to_template_submit',
				:id_column => 'id'}}
	
	
	end
	
	
 return get_data_grid(data_set,column_configs,SizerTemplatePlugins::SizerTemplateGridPlugin.new)
end


 #==========================
 #Pack group template code
 #==========================
def build_pack_group_template_grid(data_set,can_edit,can_delete)

    require File.dirname(__FILE__) + "/../../../app/helpers/tools/sizer_template_plugin.rb"
    
	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'pack_group_number'}
	column_configs[1] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'rmt_variety_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'color_sort_percentage'}
	column_configs[4] = {:field_type => 'text',:field_name => 'grade_code'}
	
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit pack_group_template',
			:settings => 
				 {:image => 'edit',
				:target_action => 'edit_pack_group_template',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete pack_group_template',
			:settings => 
				 {:image => 'delete',
				:target_action => 'delete_pack_group_template',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs,SizerTemplatePlugins::PackGroupTemplateGridPlugin.new)
end

def build_pack_group_template_form(sizer_template,pack_group_template,action,caption,is_edit = nil,is_create_retry = nil)

   
    if !pack_group_template 
      pack_group_template = PackGroupTemplate.new
      pack_group_template.pack_group_number = PackGroupTemplate.next_group_number(sizer_template.id)
      pack_group_template.commodity_code = sizer_template.commodity_code
      pack_group_template.rmt_variety_code = sizer_template.rmt_variety_code
      pack_group_template.sizer_template_code = sizer_template.template_name
    end
    
    grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map{|g|[g.grade_code]}  
    grade_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'sizer_template_code'}
						
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'pack_group_number'}

	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'commodity_code'}

	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'rmt_variety_code'}

	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'color_sort_percentage'}

	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grade_codes}}
    
    if is_edit
       field_configs[6] = {:field_type => 'LinkField',:field_name => 'counts_to_drops',
			:settings => 
				 {:link_text => 'set drops to counts',
				:target_action => 'set_drops_to_counts',
				:id_column => 'id'}}
    end
    
	build_form(pack_group_template,field_configs,action,'pack_group_template',caption,is_edit)

end


#======================
#DROPS TO COUNTS CODE
#======================

def build_pack_group_template_outlet_form(pack_group_outlet,action,caption,is_edit = nil,is_create_retry = nil)

      require File.dirname(__FILE__) + "/../../../app/helpers/tools/sizer_template_plugin.rb"

     #data needed to show pack group context to user
     
     pack_group_outlet.commodity_code = pack_group_outlet.pack_group_template.commodity_code
     pack_group_outlet.rmt_variety_code = pack_group_outlet.pack_group_template.rmt_variety_code
     pack_group_outlet.line_config_code = pack_group_outlet.pack_group_template.sizer_template.line_config_code
     pack_group_outlet.color_sort_percentage = pack_group_outlet.pack_group_template.color_sort_percentage
     pack_group_outlet.grade_code = pack_group_outlet.pack_group_template.grade_code
     pack_group_outlet.sizer_template_name = pack_group_outlet.pack_group_template.sizer_template_code
     pack_group_outlet.pack_group_number = pack_group_outlet.pack_group_template.pack_group_number
     
    
     
     line_config = pack_group_outlet.pack_group_template.sizer_template.line_config
     drops = line_config.drops.map{|d|d.drop_code.to_s}
    
    drops.unshift "<empty>"
    
    
    if !pack_group_outlet.outlet1
    #  pack_group_outlet.outlet1 = "<empty>"
    end
    if !pack_group_outlet.outlet2
    #  pack_group_outlet.outlet2 = "<empty>"
    end
    if !pack_group_outlet.outlet3
    #  pack_group_outlet.outlet3 = "<empty>"
    end
    if !pack_group_outlet.outlet4
    #  pack_group_outlet.outlet4 = "<empty>"
    end
    if !pack_group_outlet.outlet5
    #  pack_group_outlet.outlet5 = "<empty>"
    end
    if !pack_group_outlet.outlet6
    #  pack_group_outlet.outlet6 = "<empty>"
    end
    if !pack_group_outlet.outlet7
     # pack_group_outlet.outlet7 = "<empty>"
    end
    if !pack_group_outlet.outlet8
     # pack_group_outlet.outlet8 = "<empty>"
    end
    if !pack_group_outlet.outlet9
     # pack_group_outlet.outlet9 = "<empty>"
    end
    if !pack_group_outlet.outlet10
    #  pack_group_outlet.outlet10 = "<empty>"
    end
    if !pack_group_outlet.outlet11
     # pack_group_outlet.outlet11 = "<empty>"
    end
    if !pack_group_outlet.outlet12
     # pack_group_outlet.outlet12 = "<empty>"
    end
    
	field_configs = Array.new

	
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'pack_group_number'}
	
	
	
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'commodity_code'}
	
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'rmt_variety_code'}
						
	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'color_sort_percentage'}
    
    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'grade_code'}
    
    if pack_group_outlet.size_code
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'size_code'}
    else
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_value'}
    end
 

#	field_configs[8] = {:field_type => 'LabelField',
#						:field_name => 'equivalent_count_value'}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet1',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet2',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet3',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet4',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet5',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet6',
						:settings => {:list => drops,:is_clearable => true}}
						
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet7',
						:settings => {:list => drops,:is_clearable => true}}
						
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet8',
						:settings => {:list => drops,:is_clearable => true}}
						
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet9',
						:settings => {:list => drops,:is_clearable => true}}
						
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet10',
						:settings => {:list => drops,:is_clearable => true}}
						
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet11',
						:settings => {:list => drops,:is_clearable => true}}
						
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet12',
						:settings => {:list => drops,:is_clearable => true}}
   
   set_form_layout "4",nil,6
   
	build_form(pack_group_outlet,field_configs,action,'pack_group_outlet',caption,is_edit,nil,nil,nil,SizerTemplatePlugins::PackGroupOutletFormPlugin.new)

end


 def build_drops_to_counts_template_grid(data_set,can_edit)
   
    require File.dirname(__FILE__) + "/../../../app/helpers/tools/sizer_template_plugin.rb"
	column_configs = Array.new
	
	
	#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit',
			:settings => 
				 {:image => 'edit',
				:target_action => 'edit_drops_to_counts',
				:id_column => 'id'}}
	
	end
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'standard_size_count_value'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'size_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet1'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet2'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet3'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet4'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet5'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet6'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet7'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet8'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet9'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet10'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet11'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet12'}
	
    

 return get_data_grid(data_set,column_configs,SizerTemplatePlugins::CountsDropsTemplateGridPlugin.new)
 
end









end
