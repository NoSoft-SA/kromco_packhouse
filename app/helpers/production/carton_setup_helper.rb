module Production::CartonSetupHelper
 
 #PALLETIZING CRITERIA CODE
 def build_palletizing_criterium_form(palletizing_criterium,action,caption,is_edit = nil,is_create_retry = nil,is_view = nil)

  
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

	build_form(palletizing_criterium,field_configs,action,'palletizing_criteria_setup',caption,is_edit)

end
 
 #RETAIL ITEM SETUP CODE
 
  def view_retail_item_setup(retail_item_setup)
    
    
    retail_item_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	retail_item_setup.color_percentage = session[:current_carton_setup].color_percentage
	retail_item_setup.grade_code = session[:current_carton_setup].grade_code
	retail_item_setup.org = session[:current_carton_setup].org
	retail_item_setup.sequence_number = session[:current_carton_setup].sequence_number
	retail_item_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
    
    field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'item_pack_product_code'}
	
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'basic_pack_code'}
						
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
											
    
	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'pack_material_product_code'}
 
	field_configs[8] = {:field_type => 'LabelField',
						:field_name => 'mark_code'}

	field_configs[9] = {:field_type => 'LabelField',
						:field_name => 'label_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	field_configs[10] =  {:field_type => 'LabelField',
						:field_name => 'handling_product_code'}
 
	field_configs[11] = {:field_type => 'LabelField',
						:field_name => 'handling_message'}

    
    field_configs[12] = {:field_type => 'LinkField',:field_name => 'item_pack_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_item_pack_product',
				:id_column => 'id'}}
    
	build_form(retail_item_setup,field_configs,"view_carton_setup",'retail_item_setup',"back")
    
 
  end
 
 
  def build_retail_item_setup_form(retail_item_setup,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	
	session[:retail_item_setup_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: pack_material_products
	
	#Observers for combos representing the key fields of fkey table: pack_material_product_id
	handling_product_codes = HandlingProduct.find_by_sql("select distinct handling_product_code from handling_products where handling_product_type_code = 'PACK'").map{|g|[g.handling_product_code]}
	handling_product_codes.unshift("<empty>")
	
    js =  "  img = 'img_retail_item_setup_handling_product_code';"
	js += "\n img = document.getElementById('img_retail_item_setup_handling_product_code');"
	js += "\n if(img != null)img.style.display = 'none';"
	
    handling_product_observer  = {:updated_field_id => "handling_message_cell",
					 :remote_method => 'retail_item_setup_handling_product_changed',
					 :on_completed_js => js}
					 
	
	 
    
	pack_js = "\n img = document.getElementById('img_retail_item_setup_basic_pack_code');"
	pack_js += "\n if(img != null)img.style.display = 'none';"
	
    basic_pack_observer  = {:updated_field_id => "act_count_cell",
					 :remote_method => 'retail_item_setup_basic_pack_changed',
					 :on_completed_js => pack_js}
    
#	combo lists for table: pack_material_products

 
	pack_material_product_codes = Product.find_all_by_product_type_code_and_product_subtype_code("PACK_MATERIAL","RI").map{|p|p.product_code}
	if !(retail_item_setup == nil||is_create_retry)
	    retail_item_setup.act_count = retail_item_setup.item_pack_product.actual_count.to_s
	end
	
    commodity = RmtSetup.find_by_production_schedule_name(session[:current_carton_setup].production_schedule_code).commodity_code
    std_count = session[:current_carton_setup].standard_size_count_value
    carton_pack_codes = StandardSizeCount.find_all_by_commodity_code_and_standard_size_count_value(commodity,std_count).map {|c|c.basic_pack_code}
    carton_pack_codes.unshift("<empty>")
   
    mark_code = TradeEnvironmentSetup.find_by_production_schedule_id_and_trade_env_code(session[:current_prod_schedule].id,session[:current_carton_setup].trade_env_code).mark_fruit_description
    if ! retail_item_setup
     retail_item_setup = RetailItemSetup.new 
     retail_item_setup.mark_code = mark_code
     retail_item_setup.label_code = session[:current_carton_setup].fruit_sticker_code
    end
    mark_codes = Mark.get_all_for_org(session[:current_carton_setup].org)
	
	
	query =  "SELECT 
             public.pack_material_products.pack_material_product_code
             FROM
             public.pack_material_sub_types
             INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
             INNER JOIN public.pack_material_products ON (public.pack_material_sub_types.id = public.pack_material_products.pack_material_sub_type_id)
             WHERE
            (public.pack_material_types.pack_material_type_code = 'LB') AND 
            (public.pack_material_sub_types.pack_material_subtype_code = 'FRUIT')"
            
	label_codes = PackMaterialProduct.find_by_sql(query).map{|l|l.pack_material_product_code}
	retail_item_setup.std_count = session[:current_carton_setup].standard_size_count_value
	retail_item_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	retail_item_setup.color_percentage = session[:current_carton_setup].color_percentage
	retail_item_setup.grade_code = session[:current_carton_setup].grade_code
	retail_item_setup.org = session[:current_carton_setup].org
	retail_item_setup.sequence_number = session[:current_carton_setup].sequence_number
	retail_item_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	#retail_item_setup.handling_product_code = "<empty>" if !retail_item_setup.handling_product_code
	
	size_refs = SizeRef.sizes_for_commodity(commodity)
	size_refs.unshift("NOS")
	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'std_count'}
	
	
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'item_pack_product_code'}
	
	
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
											
    field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'basic_pack_code',
						:settings => {:list => carton_pack_codes,:label_caption => "count basic pack"},
						:observer => basic_pack_observer}
   
   field_configs[8] = {:field_type => 'LabelField',
						:field_name => 'act_count',
						:settings => {:label_caption => "actual count"}}
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pack_material_product_id) on related table: pack_material_products
#	----------------------------------------------------------------------------------------------
#	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
#						:field_name => 'pack_material_type_code',
#						:settings => {:list => pack_material_type_codes},
#						:observer => pack_material_type_code_observer}
    
    
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'pack_material_product_code',
						:settings => {:list => pack_material_product_codes}}
 
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'mark_code',
						:settings => {:list => mark_codes}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'label_code',
						:settings => {:list => label_codes,:label_caption => "retail item sticker"}}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'handling_product_code',
						:settings => {:list => handling_product_codes},
						:observer => handling_product_observer}
 
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'handling_message'}

    if retail_item_setup.item_pack_product
        field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'item_pack_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_item_pack_product',
				:id_column => 'id'}}
    end
    
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'size_ref',
						:settings => {:list => size_refs}}
						
	build_form(retail_item_setup,field_configs,action,'retail_item_setup',caption,is_edit)

end
 
 
 #RETAIL UNIT SETUP CODE
 def view_retail_unit_setup(retail_unit_setup)
    
     puts "hi"
    retail_unit_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	retail_unit_setup.color_percentage = session[:current_carton_setup].color_percentage
	retail_unit_setup.grade_code = session[:current_carton_setup].grade_code
	retail_unit_setup.org = session[:current_carton_setup].org
	retail_unit_setup.sequence_number = session[:current_carton_setup].sequence_number
	retail_unit_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
    retail_unit_setup.std_count = session[:current_carton_setup].standard_size_count_value
    
    field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'std_count'}
	
	
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'unit_pack_product_code'}
	
	
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
											
		
	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'pack_material_product_code'}
 
	field_configs[8] = {:field_type => 'LabelField',
						:field_name => 'mark_code'}

	field_configs[9] = {:field_type => 'LabelField',
						:field_name => 'items_per_unit'}
						
	field_configs[10] = {:field_type => 'LabelField',
						:field_name => 'units_per_carton'}

	field_configs[11] = {:field_type => 'LabelField',
						:field_name => 'label_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	field_configs[12] =  {:field_type => 'LabelField',
						:field_name => 'handling_product_code'}
 
	field_configs[13] = {:field_type => 'LabelField',
						:field_name => 'handling_message'}

    
    field_configs[14] = {:field_type => 'LinkField',:field_name => 'unit_pack_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_unit_pack_product',
				:id_column => 'id'}}
    
	build_form(retail_unit_setup,field_configs,"view_carton_setup",'retail_unit_setup',"back")
    
 
  end
 def build_retail_unit_setup_form(retail_unit_setup,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	
	session[:retail_unit_setup_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: pack_material_products
	
	
	#Observers for combos representing the key fields of fkey table: pack_material_product_id
	handling_product_codes = HandlingProduct.find_by_sql("select distinct handling_product_code from handling_products where handling_product_type_code = 'PACK'").map{|g|[g.handling_product_code]}
	handling_product_codes.unshift("<empty>")
	
    
    js =  "  img = 'img_retail_unit_setup_handling_product_code';"
	js += "\n img = document.getElementById('img_retail_unit_setup_handling_product_code');"
	js += "\n if(img != null)img.style.display = 'none';"
	
    handling_product_observer  = {:updated_field_id => "handling_message_cell",
					 :remote_method => 'retail_unit_setup_handling_product_changed',
					 :on_completed_js => js}
    
#	combo lists for table: pack_material_products
    
    pack_material_product_codes = Product.find_all_by_product_type_code_and_product_subtype_code("PACK_MATERIAL","RU").map{|p|p.product_code}
	
	product_codes = UnitPackProduct.find(:all).map{|u|u.unit_pack_product_code}
	product_codes.unshift("<empty>")
    #create instance RSI, so that we can set default values on its' fields
    retail_unit_setup = RetailUnitSetup.new if ! retail_unit_setup
    
    trade_env = TradeEnvironmentSetup.find_by_production_schedule_id_and_trade_env_code(session[:current_prod_schedule].id,session[:current_carton_setup].trade_env_code)
    mark_code = trade_env.mark_retail_unit_description 
   
    retail_unit_setup = RetailUnitSetup.new if ! retail_unit_setup
    retail_unit_setup.mark_code = mark_code if !retail_unit_setup.mark_code
    mark_codes = Mark.get_all_for_org(trade_env.organization_retailer)
	
	#label_codes = PackMaterialProduct.find_all_by_pack_material_type_code("LABEL").map{|l|l.pack_material_product_code}
	label_codes = Label.find(:all).map{|l|l.label_code}
	label_codes.unshift("<empty>")
	retail_unit_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	retail_unit_setup.color_percentage = session[:current_carton_setup].color_percentage
	retail_unit_setup.grade_code = session[:current_carton_setup].grade_code
	retail_unit_setup.org = session[:current_carton_setup].org
	retail_unit_setup.sequence_number = session[:current_carton_setup].sequence_number
	retail_unit_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	retail_unit_setup.std_count = session[:current_carton_setup].standard_size_count_value
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'std_count'}
	
	field_configs[2] = {:field_type => 'DropDownField',
						:field_name => 'unit_pack_product_code',
						:settings => {:list => product_codes}}
	
	
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
											
				
#	---------------------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pack_material_product_id) on related table: pack_material_products
#	---------------------------------------------------------------------------------------------------------
	
    
	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'pack_material_product_code',
						:settings => {:list => pack_material_product_codes}}
 
	field_configs[8] = {:field_type => 'DropDownField',
						:field_name => 'mark_code',
						:settings => {:list => mark_codes}}

	field_configs[9] = {:field_type => 'TextField',
						:field_name => 'items_per_unit'}
						
	field_configs[10] = {:field_type => 'TextField',
						:field_name => 'units_per_carton'}

	#field_configs[11] = {:field_type => 'DropDownField',
	#					:field_name => 'label_code',
	#					:settings => {:list => label_codes,:label_caption => "retail unit label"}}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	field_configs[11] =  {:field_type => 'DropDownField',
						:field_name => 'handling_product_code',
						:settings => {:list => handling_product_codes},
						:observer => handling_product_observer}
 
	field_configs[12] = {:field_type => 'LabelField',
						:field_name => 'handling_message'}

    if retail_unit_setup.unit_pack_product
        field_configs[13] = {:field_type => 'LinkField',:field_name => 'unit_pack_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_unit_pack_product',
				:id_column => 'id'}}
    end
	build_form(retail_unit_setup,field_configs,action,'retail_unit_setup',caption,is_edit)

end
 
#TRADE UNIT SECTION
 def build_trade_unit_setup_form(trade_unit_setup,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	 
	session[:trade_unit_setup_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: pack_material_products
	combos_js_for_pack_material_products = gen_combos_clear_js_for_combos(["trade_unit_setup_pack_material_type_code","trade_unit_setup_pack_material_product_code","trade_unit_setup_old_pack_code"])
	
	handling_product_codes = HandlingProduct.find_by_sql("select distinct handling_product_code from handling_products where handling_product_type_code = 'PACK'").map{|g|[g.handling_product_code]}
	handling_product_codes.unshift("<empty>")
	
					 
	pack_material_product_code_observer  = {:updated_field_id => "old_pack_code_cell",
					 :remote_method => 'trade_unit_setup_pack_material_product_code_changed',
					 :on_completed_js => combos_js_for_pack_material_products ["trade_unit_setup_pack_material_product_code"]}
					 
	
    session[:trade_unit_setup_form][:pack_material_product_code_observer] = pack_material_product_code_observer
    
    js =  "  img = 'img_trade_unit_setup_handling_product_code';"
	js += "\n img = document.getElementById('img_trade_unit_setup_handling_product_code');"
	js += "\n if(img != null)img.style.display = 'none';"
	
	cpc_js =  "  img = 'img_trade_unit_setup_carton_pack_product_code';"
	cpc_js += "\n img = document.getElementById('img_trade_unit_setup_carton_pack_product_code');"
	cpc_js += "\n if(img != null)img.style.display = 'none';"
	
    handling_product_observer  = {:updated_field_id => "handling_message_cell",
					 :remote_method => 'retail_unit_setup_handling_product_changed',
					 :on_completed_js => js}
	
					 
	cpc_observer  = {:updated_field_id => "carton_fruit_mass_label_cell",
					 :remote_method => 'trade_unit_setup_cpc_changed',
					 :on_completed_js => cpc_js}
					 
#	combo lists for table: pack_material_products
    old_packs = OldPack.find_by_sql('select distinct old_pack_code from old_packs').map{|g|[g.old_pack_code]}
    old_packs.unshift("<empty>")
    
	pack_material_type_codes = nil 
    pack_material_product_codes = Product.find_all_by_product_type_code_and_product_subtype_code("PACK_MATERIAL","TU").map{|p|p.product_code}
	
    #create instance RSI, so that we can set default values on its' fields
    trade_unit_setup = TradeUnitSetup.new if ! trade_unit_setup
    
    trade_env = TradeEnvironmentSetup.find_by_production_schedule_id_and_trade_env_code(session[:current_prod_schedule].id,session[:current_carton_setup].trade_env_code)
    mark_code = trade_env.mark_trade_unit_description
   
    trade_unit_setup.mark_code = mark_code if !trade_unit_setup||(trade_unit_setup!= nil && trade_unit_setup.mark_code == nil)
    mark_codes = Mark.get_all_for_org(session[:current_carton_setup].org)
	
	#label_codes = PackMaterialProduct.find_all_by_pack_material_type_code("LABEL").map{|l|l.pack_material_product_code}
	label_codes = Label.find(:all).map{|l|l.label_code}
	label_codes.unshift("<empty>")
	product_codes = CartonPackProduct.find_all_by_basic_pack_code(session[:current_carton_setup].retail_item_setup.basic_pack_code).map{|u|u.carton_pack_product_code}
	product_codes.unshift("<empty>")
	
	trade_unit_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	trade_unit_setup.color_percentage = session[:current_carton_setup].color_percentage
	trade_unit_setup.grade_code = session[:current_carton_setup].grade_code
	trade_unit_setup.org = session[:current_carton_setup].org
	trade_unit_setup.sequence_number = session[:current_carton_setup].sequence_number
	trade_unit_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	trade_unit_setup.std_count = session[:current_carton_setup].standard_size_count_value
#	trade_unit_setup.standard_label_code = "CTN1"  if !trade_unit_setup.standard_label_code
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'std_count'}
	
	field_configs[2] = {:field_type => 'DropDownField',
						:field_name => 'carton_pack_product_code',
						:settings => {:list => product_codes},
						:observer => cpc_observer}
	
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
											
				    
	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'pack_material_product_code',
						:settings => {:list => pack_material_product_codes},
						:observer => pack_material_product_code_observer}
 
	
	field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'old_pack_code',
						:settings => {:list => old_packs}}					
 
	field_configs[9] = {:field_type => 'DropDownField',
						:field_name => 'mark_code',
						:settings => {:list => mark_codes}}


	#field_configs[10] = {:field_type => 'DropDownField',
	#					:field_name => 'standard_label_code',
	#					:settings => {:list => label_codes,:label_caption => "trade unit label"}}
  #
   # field_configs[11] = {:field_type => 'DropDownField',
	#					:field_name => 'second_label_code',
	#					:settings => {:list => label_codes,:label_caption => "second trade unit label"}}
	
	field_configs[10] = {:field_type => 'TextArea',
						:field_name => 'remarks'}
	
	field_configs[11] = {:field_type => 'LabelField',
						:field_name => 'carton_fruit_mass_label',:settings =>
						{:label_caption => "carton_fruit_mass(system)"}}
						
						#----------------------------
						#Mass not needed here anymore
						#----------------------------
#											
#	field_configs[14] = {:field_type => 'TextField',
#						:field_name => 'carton_fruit_mass',:settings =>
#						{:label_caption => "carton_fruit_mass(packed)"}}
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	field_configs[12] =  {:field_type => 'DropDownField',
						:field_name => 'handling_product_code',
						:settings => {:list => handling_product_codes},
						:observer => handling_product_observer}
 
	field_configs[13] = {:field_type => 'LabelField',
						:field_name => 'handling_message'}

    if trade_unit_setup.carton_pack_product
        field_configs[14] = {:field_type => 'LinkField',:field_name => 'carton_pack_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_carton_pack_product',
				:id_column => 'id'}}
    end
	build_form(trade_unit_setup,field_configs,action,'trade_unit_setup',caption,is_edit)

end
 
def view_trade_unit_setup(trade_unit_setup)
    
    
    trade_unit_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	trade_unit_setup.color_percentage = session[:current_carton_setup].color_percentage
	trade_unit_setup.grade_code = session[:current_carton_setup].grade_code
	trade_unit_setup.org = session[:current_carton_setup].org
	trade_unit_setup.sequence_number = session[:current_carton_setup].sequence_number
	trade_unit_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
    trade_unit_setup.std_count = session[:current_carton_setup].standard_size_count_value
    
    field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'std_count'}
	
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'carton_pack_product_code'}
	
	
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
																	
    
	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'pack_material_product_code'}
 
	field_configs[8] = {:field_type => 'LabelField',
						:field_name => 'mark_code'}


	field_configs[9] = {:field_type => 'LabelField',
						:field_name => 'standard_label_code'}
    
    
    field_configs[10] = {:field_type => 'LabelField',
						:field_name => 'second_label_code'}
	
	field_configs[11] = {:field_type => 'LabelField',
						:field_name => 'carton_fruit_mass'}
						
    field_configs[12] = {:field_type => 'LabelField',
						:field_name => 'remarks'}
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	field_configs[13] =  {:field_type => 'LabelField',
						:field_name => 'handling_product_code'}
 
	field_configs[14] = {:field_type => 'LabelField',
						:field_name => 'handling_message'}
						
	 field_configs[15] = {:field_type => 'LabelField',
						:field_name => 'old_pack_code'}

    if trade_unit_setup.carton_pack_product
      field_configs[16] = {:field_type => 'LinkField',:field_name => 'carton_pack_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_carton_pack_product',
				:id_column => 'id'}}
    end
	build_form(trade_unit_setup,field_configs,"view_carton_setup",'trade_unit_setup',"back")
    
 
 
  end
 
 #FG SECTION
 
 
 def view_fg_setup(fg_setup)
#   ---------------------------------
#	 Define fields to build form from
#	---------------------------------

    fg_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	fg_setup.color_percentage = session[:current_carton_setup].color_percentage
	fg_setup.grade_code = session[:current_carton_setup].grade_code
	fg_setup.org = session[:current_carton_setup].org
	fg_setup.sequence_number = session[:current_carton_setup].sequence_number
	fg_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	fg_setup.std_count = session[:current_carton_setup].standard_size_count_value

	 field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'std_count'}
	
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
											
    field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'fg_product_code'}
						
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pack_material_product_id) on related table: pack_material_products
#	----------------------------------------------------------------------------------------------
	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'retailer_sell_by_code'}
    
    
	field_configs[8] =  {:field_type => 'LabelField',
						:field_name => 'inventory_code'}
 
	field_configs[9] = {:field_type => 'LabelField',
						:field_name => 'target_market'}

	field_configs[10] = {:field_type => 'LabelField',
						:field_name => 'remarks'}
    
						
	field_configs[11] = {:field_type => 'LabelField',
						:field_name => 'gtin'}
	
	
	if fg_setup.extended_fg_code
	   extended_fg_record = ExtendedFg.find_by_extended_fg_code(fg_setup.extended_fg_code)
	   if extended_fg_record
	     
         fg_setup.tu_nett_mass = extended_fg_record.tu_nett_mass 
         fg_setup.tu_gross_mass = extended_fg_record.tu_gross_mass
         fg_setup.ri_diameter_range = extended_fg_record.ri_diameter_range
         fg_setup.ri_weight_range = extended_fg_record.ri_weight_range 
         fg_setup.marking = extended_fg_record.ru_description 
	   end
	end
	
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'extended_fg_code'}
											
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'ri_weight_range'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'ri_diameter_range'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'marking'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'tu_nett_mass'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'tu_gross_mass'}
	

	build_form(fg_setup,field_configs,"view_carton_setup",'fg_setup',"back")
 
 
 end
 
 
 def build_fg_setup_form(fg_setup,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	
	trade_env = TradeEnvironmentSetup.find_by_production_schedule_id_and_trade_env_code(session[:current_prod_schedule].id,session[:current_carton_setup].trade_env_code)
    
    sell_by_code = trade_env.sell_by_code
   
    sell_by_codes = Organization.get_sell_bys_by_org("RETAILER",trade_env.organization_retailer)
    sell_by_codes.unshift("<empty>")
    inv_codes = InventoryCode.get_all_by_org(session[:current_carton_setup].org)
    inv_codes.unshift("<empty>")
    target_market = trade_env.target_market_description
    target_markets = TargetMarket.get_all_by_org(session[:current_carton_setup].org)
	target_markets.unshift("<empty>")
	
	if ! fg_setup
	   fg_setup = FgSetup.new
	   fg_setup.target_market = session[:current_carton_setup].cloned_target_market_code
	   fg_setup.inventory_code = session[:current_carton_setup].cloned_inventory_code
	   
	   fg_setup.retailer_sell_by_code = sell_by_code
	   fg_setup.target_market = target_market if !fg_setup.target_market
	   
	end
	
	fg_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	fg_setup.color_percentage = session[:current_carton_setup].color_percentage
	fg_setup.grade_code = session[:current_carton_setup].grade_code
	fg_setup.org = session[:current_carton_setup].org
	fg_setup.sequence_number = session[:current_carton_setup].sequence_number
	fg_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	fg_setup.std_count = session[:current_carton_setup].standard_size_count_value
	
	fg_mark_css = "red_label_field"
	  ri_mark = session[:current_carton_setup].retail_item_setup.mark_code
	  ru_mark = session[:current_carton_setup].retail_unit_setup.mark_code
	  tu_mark = session[:current_carton_setup].trade_unit_setup.mark_code

	  
	
	  fg_mark_code = ""
	  fg_mark_css = "red_label_field"
	
	  if ri_mark && ru_mark && tu_mark
	     fg_mark_css = "green_label_field"
	     fg_setup.fg_mark_code = FgMark.create_if_needed(ri_mark,ru_mark,tu_mark)
	    
	  else
	    missing = ""
	    missing += "RI_MARK NOT SET <br>" if !ri_mark
	    missing += "RU_MARK NOT SET <br>" if !ru_mark
	    missing += "TU_MARK NOT SET" if !tu_mark
	    fg_setup.fg_mark_code = missing
	    
	  end
	
	  puts "FGM: " +  fg_setup.fg_mark_code
	
	#-----------------------
	#Calculate old fg_code
	#-----------------------
	actual_count_code = session[:current_carton_setup].retail_item_setup.item_pack_product.actual_count.to_s
    if !(session[:current_carton_setup].retail_item_setup.item_pack_product.size_ref == "NOS"||session[:current_carton_setup].retail_item_setup.item_pack_product.size_ref == nil)
      actual_count_code = session[:current_carton_setup].retail_item_setup.item_pack_product.size_ref
    end
    
	rmt_setup = RmtSetup.find_by_production_schedule_name(session[:current_carton_setup].production_schedule_code)
  
  if tu_mark
	   brand_code = Mark.find_by_mark_code(tu_mark).brand_code
	   fg_setup.fg_code_old = rmt_setup.commodity_code + " " + session[:current_carton_setup].marketing_variety_code + " " + brand_code + " " + session[:current_carton_setup].trade_unit_setup.old_pack_code.to_s + " " + actual_count_code
  end
  
	if fg_mark_css.index("green")
	  
	  units = session[:current_carton_setup].retail_unit_setup.units_per_carton
	  units = "*" if !units ||units.to_s.strip == ""
	  fg_code = ""
	  fg_code += session[:current_carton_setup].retail_item_setup.item_pack_product_code + "_" 
	  fg_code += units.to_s
      fg_code += session[:current_carton_setup].retail_unit_setup.unit_pack_product_code + "_"
      fg_code += session[:current_carton_setup].trade_unit_setup.carton_pack_product_code
	  fg_setup.extended_fg_code = fg_code + "_" + session[:current_carton_setup].org + "_" + fg_setup.fg_mark_code 
	  
	end
	 
	if fg_setup.extended_fg_code
	   extended_fg_record = ExtendedFg.find_by_extended_fg_code(fg_setup.extended_fg_code)
	   if extended_fg_record
	     
	     fg_setup.extended_fg_id = extended_fg_record.id
         fg_setup.tu_nett_mass = extended_fg_record.tu_nett_mass 
         fg_setup.tu_gross_mass = extended_fg_record.tu_gross_mass
         fg_setup.ri_diameter_range = extended_fg_record.ri_diameter_range
         fg_setup.ri_weight_range = extended_fg_record.ri_weight_range 
         fg_setup.marking = extended_fg_record.ru_description 
	   end
	else
	 fg_setup.extended_fg_code = "NOT CREATED YET"
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'std_count'}
	
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'fg_product_code'}
						
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
											

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pack_material_product_id) on related table: pack_material_products
#	----------------------------------------------------------------------------------------------
	field_configs[7] =  {:field_type => 'TextField',
						:field_name => 'retailer_sell_by_code'}
    
    
	field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'inventory_code',
						:settings => {:list => inv_codes}}
 
	field_configs[9] = {:field_type => 'DropDownField',
						:field_name => 'target_market',
						:settings => {:list => target_markets}}

	field_configs[10] = {:field_type => 'TextArea',
						:field_name => 'remarks'}
 
    field_configs[11] = {:field_type => 'LabelField',
						:field_name => 'fg_product_code'}
						
	field_configs[12] = {:field_type => 'LabelField',
						:field_name => 'gtin'}
	
	if fg_setup.fg_product
      field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'fg_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_fg_product',
				:id_column => 'id'}}
    end
    
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'fg_mark_code',
						:settings => {:css_class => fg_mark_css }}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'fg_code_old'}
	
	if !ExtendedFg.find_by_extended_fg_code(fg_setup.extended_fg_code)					
	   field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'extended_fg_code',
						:settings => {:css_class => "red_label_field"}}
    else
      field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'extended_fg_code',
			:settings => 
				 {:link_text => fg_setup.extended_fg_code,
				:target_action => 'edit_extended_fg_code',
				:id_column => 'extended_fg_id'}}
	
	end
	
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'ri_weight_range'}
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'ri_diameter_range'}
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'marking'}
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'tu_nett_mass'}
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'tu_gross_mass'}
											
    @fg_setup = fg_setup
	build_form(fg_setup,field_configs,action,'fg_setup',caption,is_edit)

end
 
 #PALLET SETUP CODE
 def view_pallet_setup(pallet_setup)
    
    
    pallet_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	pallet_setup.color_percentage = session[:current_carton_setup].color_percentage
	pallet_setup.grade_code = session[:current_carton_setup].grade_code
	pallet_setup.org = session[:current_carton_setup].org
	pallet_setup.sequence_number = session[:current_carton_setup].sequence_number
	pallet_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
    
    field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'pallet_format_product_code'}
	
	
	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}

	field_configs[6] =  {:field_type => 'LabelField',
						:field_name => 'pack_material_product_code'}
 
	field_configs[7] = {:field_type => 'LabelField',
						:field_name => 'remarks'}

	field_configs[8] = {:field_type => 'LabelField',
						:field_name => 'no_of_cartons'}

    field_configs[9] = {:field_type => 'LabelField',
						:field_name => 'inspection_type_code'}

	field_configs[10] = {:field_type => 'LabelField',
						:field_name => 'label_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	field_configs[11] =  {:field_type => 'LabelField',
						:field_name => 'handling_product_code'}
 
	field_configs[12] = {:field_type => 'LabelField',
						:field_name => 'handling_message'}

    
    field_configs[13] = {:field_type => 'LinkField',:field_name => 'pallet_format_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_pallet_format_product',
				:id_column => 'id'}}
    
	build_form(pallet_setup,field_configs,"view_carton_setup",'retail_item_setup',"back")
    
 
  end
 
 
  def build_pallet_setup_form(pallet_setup,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	
	session[:pallet_setup_form]= Hash.new
	
	combos_js_for_num_cartons = gen_combos_clear_js_for_combos(["pallet_setup_pallet_format_product_code","pallet_setup_no_of_cartons"])
	
	
	pallet_format_product_observer  = {:updated_field_id => "no_of_cartons_cell",
					 :remote_method => 'pallet_setup_pallet_format_product_code_changed',
					 :on_completed_js => combos_js_for_num_cartons ["pallet_setup_pallet_format_product_code"]}
	
	
	
	#Observers for combos representing the key fields of fkey table: pack_material_product_id
	handling_product_codes = HandlingProduct.find_by_sql("select distinct handling_product_code from handling_products where handling_product_type_code = 'PACK'").map{|g|[g.handling_product_code]}
	handling_product_codes.unshift("<empty>")
	
	
    js =  "  img = 'img_pallet_setup_handling_product_code';"
	js += "\n img = document.getElementById('img_pallet_setup_handling_product_code');"
	js += "\n if(img != null)img.style.display = 'none';"
	
    handling_product_observer  = {:updated_field_id => "handling_message_cell",
					 :remote_method => 'pallet_setup_handling_product_changed',
					 :on_completed_js => js}
    
#	combo lists for table: pack_material_products
 
	pack_material_product_codes = Product.find_all_by_product_type_code_and_product_subtype_code("PACK_MATERIAL","LU").map{|p|p.product_code}
    num_cartons_list = nil
	
	if pallet_setup == nil||is_create_retry
		 num_cartons_list = ["Select a value from pallet format product"] 
	else
	    num_cartons_list = PalletFormatProduct.cartons_per_pallet_codes(pallet_setup.carton_setup.trade_unit_setup.carton_pack_product_code,pallet_setup.pallet_format_product_code)
	end
	
    std_count = session[:current_carton_setup].standard_size_count_value
        
    product_codes = PalletFormatProduct.find(:all).map{|u|u.pallet_format_product_code}
    
    product_codes.unshift("<empty>")
    
    if !pallet_setup
     
     pallet_setup = PalletSetup.new 
    end
    
  inspection_types = InspectionType.find_all_by_grade_code_and_for_internal_hg_inspections_only(session[:current_carton_setup].grade_code,false).map{|g|[g.inspection_type_code]}
	#inspection_types.unshift("<empty>")
	#label_codes = PackMaterialProduct.find_all_by_pack_material_type_code("LABEL").map{|l|l.pack_material_product_code}
	label_codes = Label.find(:all).map{|l|l.label_code}
	pallet_setup.std_count = session[:current_carton_setup].standard_size_count_value
	pallet_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	pallet_setup.color_percentage = session[:current_carton_setup].color_percentage
	pallet_setup.grade_code = session[:current_carton_setup].grade_code
	pallet_setup.org = session[:current_carton_setup].org
	pallet_setup.sequence_number = session[:current_carton_setup].sequence_number
	pallet_setup.production_schedule_code = session[:current_carton_setup].production_schedule_code
	#pallet_setup.label_code = "PAL1" if !pallet_setup.label_code
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
	
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'std_count'}
	
	
	field_configs[2] = {:field_type => 'DropDownField',
						:field_name => 'pallet_format_product_code',
						:settings => {:list => product_codes},
						:observer => pallet_format_product_observer}
	
	
	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'color_percentage'}
						
	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'grade_code'}
						
	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'org'}
	
	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
											

	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'pack_material_product_code',
						:settings => {:list => pack_material_product_codes}}
 
	field_configs[8] = {:field_type => 'DropDownField',
						:field_name => 'inspection_type_code',
						:settings => {:list => inspection_types, :no_empty => true}}

	field_configs[9] = {:field_type => 'DropDownField',
						:field_name => 'no_of_cartons',
						:settings => {:list => num_cartons_list}}


    field_configs[10] = {:field_type => 'TextArea',
						:field_name => 'remarks'}
						
						
	#field_configs[11] = {:field_type => 'DropDownField',
	#					:field_name => 'label_code',
	#					:settings => {:list => label_codes,:label_caption => "logistical unit label"}}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (handling_product_id) on related table: handling_products
#	----------------------------------------------------------------------------------------------
	field_configs[11] =  {:field_type => 'DropDownField',
						:field_name => 'handling_product_code',
						:settings => {:list => handling_product_codes},
						:observer => handling_product_observer}
 
	field_configs[12] = {:field_type => 'LabelField',
						:field_name => 'handling_message'}

    if pallet_setup.pallet_format_product
        field_configs[13] = {:field_type => 'LinkField',:field_name => 'pallet_format_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_pallet_format_product',
				:id_column => 'id'}}
    end
	build_form(pallet_setup,field_configs,action,'pallet_setup',caption,is_edit)

end
 

 #CARTON SETUP CODE
 
 
 def view_carton_setup(carton_setup)

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
						:field_name => 'qty_required'}
						
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'qty_produced'}
	
	 if carton_setup.retail_item_setup					
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'retail_item_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'edit_retail_item_setup',
				:id_column => 'id'}}
	
	 end
	
	 if carton_setup.retail_unit_setup
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'retail_unit_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'edit_retail_unit_setup',
				:id_column => 'id'}}
				
	 end
	
	if carton_setup.trade_unit_setup			
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'trade_unit_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'edit_trade_unit_setup',
				:id_column => 'id'}}
    end
	
	if carton_setup.fg_setup			
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'fg_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'edit_fg_setup',
				:id_column => 'id'}}
	end
	if carton_setup.pallet_setup			
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'pallet_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'edit_pallet_setup',
				:id_column => 'id'}}
    end
    
    if carton_setup.palletizing_criterium
	  field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'palletizing_criteria',
			:settings => 
				 {:link_text => 'view_pallet_criteria',
				:target_action => 'palletizing_criteria_setup',
				:id_column => 'id'}}
    end
    
	build_form(carton_setup,field_configs,"view_paging_handler",'carton_setup',"back",nil,nil,nil,nil,CartonSetupPlugins::CartonSetupFormPlugin.new)

end
 
 
 
 
 def build_carton_setup_form(carton_setup,action,caption,is_edit = nil,is_create_retry = nil)
     #-------------
	 #  Luks Code -
	 #-------------
	 
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:carton_setup_edit_form]= Hash.new
	
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js_for_carton_set_up = gen_combos_clear_js_for_combos(["carton_setup_order_number"])
	on_complete_js = "\n img = document.getElementById('img_carton_setup_order_number');"
	on_complete_js += "\n if(img != null) img.style.display = 'none';"
	#Observers for search combos
	carton_setup_order_number_observer  = {:updated_field_id => "qty_required_cell",
					 :remote_method => 'carton_setup_order_number_look_up_combo_changed',
					 :on_completed_js => on_complete_js}

	session[:carton_setup_edit_form][:carton_setup_order_number_observer] = carton_setup_order_number_observer
	 
	 #-------------
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

     require File.dirname(__FILE__) + "/../../../app/helpers/production/carton_setup_plugin.rb"

	 field_configs = Array.new
	 
	 org_list = TradeEnvironmentSetup.find_by_sql("select trade_env_code from public.trade_environment_setups where (public.trade_environment_setups.production_schedule_id = '#{session[:current_prod_schedule].id}')").map{|org|org.trade_env_code}
	 org_list.unshift("<empty>")
	 grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map{|g|[g.grade_code]}
	 grade_codes.unshift("<empty>")
	 class_codes = ProductClass.find_by_sql('select distinct product_class_code from product_classes').map{|g|[g.product_class_code]}
	 
	 #-------------
	 #  Luks Code -
	 #-------------
	 order_numbers = SeasonOrderQuantity.find_by_sql("select * from season_order_quantities where season_code = '#{carton_setup.production_schedule.season_code}' ").map{|s|[s.customer_order_number]}
	 carton_setup.order_number = "n.a." if !carton_setup.order_number
	
	 #-------------
	 field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_code'}
    
     field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'carton_setup_code'}
	 
	 field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'org',:settings =>
						{:label_caption => "marketing_org"}}

	 field_configs[3] = {:field_type => 'DropDownField',
						:field_name => 'trade_env_code',
						:settings => {:list => org_list}}

	 field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_value'}
						
#  if carton_setup && carton_setup.production_schedule && carton_setup.production_schedule.production_schedule_status_code == "re_opened"
#	     field_configs[5] = {:field_type => 'LabelField',
#						:field_name => 'color_percentage'}
#						
#	     field_configs[6] = {:field_type => 'LabelField',
#						:field_name => 'grade_code'}
						
	#  else
	     field_configs[5] = {:field_type => 'TextField',
						:field_name => 'color_percentage'}
						
	    field_configs[6] = {:field_type => 'DropDownField',
						:field_name => 'grade_code',
						:settings => {:list => grade_codes}}
	  
	#  end
	  
	  field_configs[7] = {:field_type => 'DropDownField',
						:field_name => 'product_class_code',
						:settings => {:list => class_codes}}
						
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'treatment_code'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'commodity_code'}
						
	  field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'marketing_variety_code'}

	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'sequence_number'}
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'pack_order'}

	 field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'order_number',
						:settings => {:list => order_numbers},
						:observer => carton_setup_order_number_observer}
						
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'qty_required'}
						
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'qty_produced'}
						
	 field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'retail_item_setup',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_retail_item_setup',
				:id_column => 'id'}}
	
	
	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'retail_unit_setup',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_retail_unit_setup',
				:id_column => 'id'}}
				
	if carton_setup.retail_item_setup			
	   field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'trade_unit_setup',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_trade_unit_setup',
				:id_column => 'id'}}
    else
        field_configs[field_configs.length()] = {:field_type => 'LabelField',
						    :field_name => 'trade_unit_setup'}
	
	end		
	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'fg_setup',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_fg_setup',
				:id_column => 'id'}}
				
	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'pallet_setup',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_pallet_setup',
				:id_column => 'id'}}
	
	#palletizing_criteria_setup
	if carton_setup.production_schedule.pallet_criterium
	  field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'palletizing_criteria',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'palletizing_criteria_setup',
				:id_column => 'id'}}
    end
	
	
	build_form(carton_setup,field_configs,action,'carton_setup',caption,is_edit,nil,nil,nil,CartonSetupPlugins::CartonSetupFormPlugin.new)

end
 
 
 def build_clone_to_count_form(carton_setup,action,caption)
 
    js = gen_combos_clear_js_for_combos(["carton_setup_standard_size_count_value","carton_setup_carton_setup_code"])
   
    counts_observer  = {:updated_field_id => "carton_setup_code_cell",
					 :remote_method => 'clone_to_count_changed',
					 :on_completed_js => js}
 
   smallest_count = ProcessingSetup.smallest_std_count_for_pack(carton_setup.production_schedule_code)
   biggest_count = ProcessingSetup.biggest_std_count_for_pack(carton_setup.production_schedule_code)
   commodity_code = carton_setup.production_schedule.rmt_setup.commodity_code
  
  
    counts = StandardSizeCount.find_by_sql("Select distinct standard_size_count_value from standard_size_counts where (
	                      commodity_code = '#{commodity_code}' and standard_size_count_value >= '#{smallest_count}' and
	                      standard_size_count_value <= '#{biggest_count}')").map {|c|c.standard_size_count_value}
    
    counts.unshift("<empty>")
    counts.delete(carton_setup.standard_size_count_value)
    
    field_configs = Array.new
  
	field_configs[0] = {:field_type => 'DropDownField',
						:field_name => 'standard_size_count_value',
						:settings => {:list => counts},
						:observer => counts_observer}
						
   field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'carton_setup_code',
						:settings => {:list => ["select a value from 'standard_size_count_value'"]}}			
    
   build_form(carton_setup,field_configs,action,'carton_setup',caption,true)
 
 end
 
         
 def build_carton_setup_grid(data_set,can_edit,can_delete,multi_select = nil)
     
	column_configs = Array.new
	require File.dirname(__FILE__) + "/../../../app/helpers/production/carton_setup_plugin.rb"
	
#	----------------------
#	define action columns
#	----------------------
    
#    column_configs[column_configs.length()] = {:field_type => 'checkbox',:field_name => 'c_test',
#			:settings => 
#				 {:target_action => 'check_test'}}
#   column_configs << {:field_type => 'action',:field_name => 'activate/deactivate',
#			:settings =>
#				 {:link_text => '',
#				:target_action => '',
#				:id_column => 'id'}}   if multi_select
				
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit carton_setup',:col_width => 50,
			:settings => 
				 {:image => 'edit',
				:target_action => 'edit_carton_setup',
				:id_column => 'id'}}
				
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'clone carton_setup',:col_width => 50,
			:settings => 
				 {:image => 'clone',
				:target_action => 'clone_carton_setup',
				:id_column => 'id'}}
				
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'clone carton_setup to count',:col_width => 50,
			:settings => 
				 {:image => 'clone_to_count',
				:target_action => 'clone_carton_setup_to_count',
				:id_column => 'id'}}
				
    else
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view carton_setup',:col_width => 50,
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_carton_setup',
				:id_column => 'id'}}
     
    end
	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete carton_setup', :col_width => 50,
			:settings => 
				 {:image => 'delete',
				:target_action => 'delete_carton_setup',
				:id_column => 'id'},:html_options => {:prompt => "This delete will cascade to all data associated with the carton_setup. Are you sure you want to do this?"}}
	end
	
##====================	
	    column_configs[ column_configs.length()]={:field_type=>'link_window',:field_name =>'view carton label', :col_width => 50,
                       :settings =>
                      {:id_column => 'id',
                       :null_test => "vr_extended_fg_code == nil",
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'view_label_for_carton_setup',
                       :image => 'label'} }
##====================		
#
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'color_percentage',:column_caption => "color",:col_width => 50,:column_caption => '% color'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'standard_size_count_value',:column_caption => "cnt",:col_width => 50}
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pack_order',:pack_order => 65}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'order_number',:column_caption => 'order_no',:col_width => 140}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'qty_required',:column_caption => 'qty_required',:col_width => 62}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'qty_produced',:column_caption => 'qty_produced',:col_width => 62}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vr_tm',:column_caption => 'tm',:col_width => 65}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vr_inv',:column_caption => 'inv',:col_width => 46}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vr_extended_fg_code',:column_caption => 'extended_fg_code',:col_width => 517}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vr_old_fg',:column_caption => 'old_fg_code',:col_width => 173}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vr_marking',:column_caption => 'marking',:col_width => 100}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vr_dia',:column_caption => 'dia',:col_width => 100}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vr_palletizing',:column_caption =>'palletizing',:col_width => 100}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vr_all_remarks',:column_caption => 'remarks',:col_width => 40}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'carton_setup_code',:col_width => 120}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name =>'id'}
    @multi_select = "selected_active_setups"   if multi_select


return get_data_grid(data_set,column_configs,CartonSetupPlugins::CartonSetupGridPlugin.new,nil)
end
 
 def build_carton_setup_grid_orig(data_set,can_edit,can_delete)

	column_configs = Array.new
	require File.dirname(__FILE__) + "/../../../app/helpers/production/carton_setup_plugin.rb"
	column_configs[0] = {:field_type => 'text',:field_name => 'color_percentage'}
	column_configs[1] = {:field_type => 'text',:field_name => 'grade_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'standard_size_count_value'}
	column_configs[3] = {:field_type => 'text',:field_name => 'org'}
	column_configs[4] = {:field_type => 'text',:field_name => 'carton_setup_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'fg_product_code'}
	column_configs[6] = {:field_type => 'text',:field_name => 'trade_env_code'}
	column_configs[7] = {:field_type => 'text',:field_name => 'sequence_number'}
	column_configs[8] = {:field_type => 'text',:field_name => 'order_number'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit carton_setup',
			:settings => 
				 {:image => 'edit',
				:target_action => 'edit_carton_setup',
				:id_column => 'id'}}
				
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'clone carton_setup',
			:settings => 
				 {:image => 'clone',
				:target_action => 'clone_carton_setup',
				:id_column => 'id'}}
				
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'clone carton_setup to count',
			:settings => 
				 {:image => 'clone_to_count',
				:target_action => 'clone_carton_setup_to_count',
				:id_column => 'id'}}
				
    else
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view carton_setup',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_carton_setup',
				:id_column => 'id'}}
    
    end
	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete carton_setup',
			:settings => 
				 {:image => 'delete',
				:target_action => 'delete_carton_setup',
				:id_column => 'id'},:html_options => {:prompt => "This delete will cascade to all data associated with the carton_setup. Are you sure you want to do this?"}}
	end
 return get_data_grid(data_set,column_configs,CartonSetupPlugins::CartonSetupGridPlugin.new)
end

#---------------------------------------------------------------------------------
#--------------- Luks code for season_order_quantities CRUD ----------------------
#---------------------------------------------------------------------------------
def build_season_order_quantity_form(season_order_quantity,action,caption,is_edit = nil,is_create_retry = nil,is_view = nil)#-----Luks
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:season_order_quantity_form]= Hash.new
	
	season_codes = Season.find_by_sql("select * from seasons").map{|g|[g.season_code]}
	season_codes.unshift("<empty>")
	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	field_configs = Array.new
 if is_view
	 field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'season_code'}
	
	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'customer_order_number'}

	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'quantity_required'}

	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'quantity_produced'}
else
   field_configs[field_configs.length] = {:field_type => 'DropDownField',
						:field_name => 'season_code',
						:settings => {:list => season_codes}}
	
	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'customer_order_number'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'quantity_required'}

	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'quantity_produced',
						:settings => {:static_value => 0,
                                      :show_label => true}}

end
	build_form(season_order_quantity,field_configs,action,'season_order_quantity',caption,is_edit)

end
 
 
 def build_season_order_quantity_search_form(season_order_quantity,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:season_order_quantity_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["season_order_quantity_season_code","season_order_quantity_customer_order_number"])
	#Observers for search combos
	season_code_observer  = {:updated_field_id => "customer_order_number_cell",
					 :remote_method => 'season_order_quantity_season_code_search_combo_changed',
					 :on_completed_js => search_combos_js["season_order_quantity_season_code"]}

	session[:season_order_quantity_search_form][:season_code_observer] = season_code_observer

 
	season_codes = SeasonOrderQuantity.find_by_sql('select distinct season_code from season_order_quantities').map{|g|[g.season_code]}
	season_codes.unshift("<empty>")
	if is_flat_search
		customer_order_numbers = SeasonOrderQuantity.find_by_sql('select distinct customer_order_number from season_order_quantities').map{|g|[g.customer_order_number]}
		customer_order_numbers.unshift("<empty>")
		season_code_observer = nil
	else
		 customer_order_numbers = ["Select a value from season_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'season_code',
						:settings => {:list => season_codes},
						:observer => season_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'customer_order_number',
						:settings => {:list => customer_order_numbers}}
 
	build_form(season_order_quantity,field_configs,action,'season_order_quantity',caption,false)

end



 def build_season_order_quantity_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'customer_order_number'}
	column_configs[1] = {:field_type => 'text',:field_name => 'quantity_required'}
	column_configs[2] = {:field_type => 'text',:field_name => 'quantity_produced'}
	column_configs[3] = {:field_type => 'text',:field_name => 'season_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit season_order_quantity',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_season_order_quantity',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete season_order_quantity',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_season_order_quantity',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

#---------------------------------------------------------------------------------
#--------------- End Luks code for season_order_quantities CRUD ------------------
#---------------------------------------------------------------------------------
end
