module Products::PackMaterialProductHelper
 
 
 #================
 #COMPOSITES CODE
 #================
 
 def build_product_form(product,action,caption,is_edit = nil,is_create_retry = nil)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    subtypes = ProductSubtype.find_all_by_product_type_code("PACK_MATERIAL").map {|p|[p.product_subtype_code]}
	
	field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'product_code'}
	
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'product_subtype_code',
						:settings => {:list => subtypes}}					

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'product_name'}

	field_configs[3] = {:field_type => 'DateField',
						:field_name => 'introduction_date'}

	field_configs[4] = {:field_type => 'DateField',
						:field_name => 'discontinue_date'}

	field_configs[5] = {:field_type => 'TextField',
						:field_name => 'remarks'}

	field_configs[6] = {:field_type => 'TextField',
						:field_name => 'tag1'}

	field_configs[7] = {:field_type => 'TextField',
						:field_name => 'tag2'}

	field_configs[8] = {:field_type => 'TextField',
						:field_name => 'tag3'}

	field_configs[9] = {:field_type => 'TextArea',
						:field_name => 'description'}

	build_form(product,field_configs,action,'product',caption,is_edit)

end
 
 
 def build_edit_quantity_form(composite,action)
   
   field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'TextField',
						:field_name => 'quantity'}
 
	
	build_form(composite,field_configs,action,'composite',"save",true)
 
 
 end
 
 
 #---------------------------------------------------------------------------------------------
 #This method recursively builds a tree structure for a given composite product
 #The passed-in node is of type 'composite_product', so, in order to find its'
 #children, it must find it's representation in the products table and from there
 #find its' children. Inside this method:
 # -> the child_node (child)is build, as well as each of it's top level children
 # Except for the rootnode- in this case the child node is not build, only its' children
 # The build process ends when a given node doesn't have any more children (composite products)
 #---------------------------------------------------------------------------------------------
 def expand_child(composite,node,is_root_child = nil)
 puts "in expand"
  comp_product = Product.find_by_product_code(composite.childproduct_code)
  child_node = nil
  
  type = "simple_child"
  type = "complex_child" if comp_product.is_composite == true
  
  if is_root_child
   if comp_product.is_composite == true
    type = "complex_root_child"
   else
    type = "simple_root_child"
   end
  
  end
  
  node_caption = comp_product.product_code + ":" + composite.quantity.to_s
  child_node = node.add_child(node_caption,type,comp_product.id.to_s)
  
  
  if comp_product.is_composite == true && comp_product.composite_products.length > 0
    #build all the first level nodes
    
    comp_product.composite_products.each do |comp_child|
     if comp_child.childproduct_code != nil
      
       expand_child(comp_child,child_node)
     end
    end
  end
 
 end
 
 def build_add_product_form()
  
   combos_js = gen_combos_clear_js_for_combos(["product_product_subtype_code","product_product_code"])
  
   product_subtype_code_observer  = {:updated_field_id => "product_code_cell",
					 :remote_method => 'product_product_subtype_code_combo_changed',
					 :on_completed_js => combos_js["product_product_subtype_code"]}
 
  
   product_subtype_codes = Product.find_by_sql("select distinct product_subtype_code from products where product_type_code = 'PACK_MATERIAL'").map{|g|[g.product_subtype_code]}
   product_subtype_codes.unshift "<empty>"
   field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'product_subtype_code',
						:settings => {:list => product_subtype_codes},
						:observer => product_subtype_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'product_code',
						:settings => {:list => ["<select a value from product subtype>"]}}
						
   
   field_configs[2] =  {:field_type => 'TextField',
						:field_name => 'quantity'}
   
   build_form(nil,field_configs,'add_product_submit','product','add',false)
   
 end
 
 
 
 def build_composite_tree(composite)
 
  menu1 = ApplicationHelper::ContextMenu.new("composites","composites")
  menu1.add_command("add pack material",url_for(:action => "add_product"))
 
  menu2 = ApplicationHelper::ContextMenu.new("simple_root_child","composites")
  menu2.add_command("remove pack material",url_for(:action => "remove_product"))
  menu2.add_command("change quantity",url_for(:action => "change_quantity"))
  
  menu3 = ApplicationHelper::ContextMenu.new("complex_root_child","composites")
  menu3.add_command("remove composite pack material",url_for(:action => "remove_product"))
  menu3.add_command("change quantity",url_for(:action => "change_quantity"))
 
  root_node = ApplicationHelper::TreeNode.new(composite.product_code,"composites",true,"composites",composite.id.to_s)
  #recursively build all chidren, but only add 'remove' menu items for the top level items
  composite.composite_products.each do |child|
  #--------------------------------------------------------------------------------------------------------
  #NB, relating to how composites are structured:
  #    Every first level child of a product that is a composite, will be a composite record
  #    that is structured as follows:
  #      -> The product_code, will be the product_code of the parent(passed in composite to this function)
  #      -> The childproduct_code will be the code of the actual first_level child
  #--------------------------------------------------------------------------------------------------------
    if child.childproduct_code != nil #a child code of nil is the parent itself
     expand_child(child,root_node,true)#these guys will not get any menus associated with them- they are read-only
    end
  end
   
   tree = ApplicationHelper::TreeView.new(root_node,"composites")
   tree.add_context_menu(menu1)
   tree.add_context_menu(menu2)
   tree.add_context_menu(menu3)
   tree.render
 
 end
 
 
 def build_product_search_form(product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:product_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["product_product_subtype_code","product_tag1","product_tag2","product_tag3","product_product_code"])
	#Observers for search combos
	product_subtype_code_observer  = {:updated_field_id => "tag1_cell",
					 :remote_method => 'product_product_subtype_code_search_combo_changed',
					 :on_completed_js => search_combos_js["product_product_subtype_code"]}

	session[:product_search_form][:product_subtype_code_observer] = product_subtype_code_observer

	tag1_observer  = {:updated_field_id => "tag2_cell",
					 :remote_method => 'product_tag1_search_combo_changed',
					 :on_completed_js => search_combos_js["product_tag1"]}

	session[:product_search_form][:tag1_observer] = tag1_observer

	tag2_observer  = {:updated_field_id => "tag3_cell",
					 :remote_method => 'product_tag2_search_combo_changed',
					 :on_completed_js => search_combos_js["product_tag2"]}

	session[:product_search_form][:tag2_observer] = tag2_observer

	tag3_observer  = {:updated_field_id => "product_code_cell",
					 :remote_method => 'product_tag3_search_combo_changed',
					 :on_completed_js => search_combos_js["product_tag3"]}

	session[:product_search_form][:tag3_observer] = tag3_observer

 
	product_subtype_codes = Product.find_by_sql("select distinct product_subtype_code from products where product_type_code = 'PACK_MATERIAL' and is_composite = 'true'").map{|g|[g.product_subtype_code]}
	product_subtype_codes.unshift("<empty>")
	if is_flat_search
		tag1s = Product.find_by_sql("select distinct tag1 from products where product_type_code = 'PACK_MATERIAL' and is_composite = 'true'").map{|g|[g.tag1]}
		tag1s.unshift("<empty>")
		tag2s = Product.find_by_sql("select distinct tag2 from products where product_type_code = 'PACK_MATERIAL' and is_composite = 'true'").map{|g|[g.tag2]}
		tag2s.unshift("<empty>")
		tag3s = Product.find_by_sql("select distinct tag3 from products where product_type_code = 'PACK_MATERIAL' and is_composite = 'true'").map{|g|[g.tag3]}
		tag3s.unshift("<empty>")
		product_codes = Product.find_by_sql("select distinct product_code from products where product_type_code = 'PACK_MATERIAL' and is_composite = 'true'" ).map{|g|[g.product_code]}
		product_codes.unshift("<empty>")
		product_subtype_code_observer = nil
		tag1_observer = nil
		tag2_observer = nil
		tag3_observer = nil
	else
		 tag1s = ["Select a value from product_subtype_code"]
		 tag2s = ["Select a value from tag1"]
		 tag3s = ["Select a value from tag2"]
		 product_codes = ["Select a value from tag3"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'product_subtype_code',
						:settings => {:list => product_subtype_codes},
						:observer => product_subtype_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'tag1',
						:settings => {:list => tag1s},
						:observer => tag1_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'tag2',
						:settings => {:list => tag2s},
						:observer => tag2_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'tag3',
						:settings => {:list => tag3s},
						:observer => tag3_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'product_code',
						:settings => {:list => product_codes}}
 
	build_form(product,field_configs,action,'product',caption,false)

end



 def build_product_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'product_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'product_subtype_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'product_name'}
	column_configs[3] = {:field_type => 'text',:field_name => 'introduction_date'}
	column_configs[4] = {:field_type => 'text',:field_name => 'discontinue_date'}
	column_configs[5] = {:field_type => 'text',:field_name => 'remarks'}
	column_configs[6] = {:field_type => 'text',:field_name => 'product_type_code'}
	column_configs[7] = {:field_type => 'text',:field_name => 'tag1'}
	column_configs[8] = {:field_type => 'text',:field_name => 'tag2'}
	column_configs[9] = {:field_type => 'text',:field_name => 'tag3'}
	column_configs[10] = {:field_type => 'text',:field_name => 'description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit composite',
			:settings => 
				 {:image => 'edit',
				:target_action => 'edit_product',
				:id_column => 'id'}}
				
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'build',
			:settings => 
				 {:image => 'build_composite',
				:target_action => 'build_composite',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete composite',
			:settings => 
				 {:image => 'delete',
				:target_action => 'delete_product',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 
 #===============
 #PRIMITIVES CODE
 #===============
 
 def build_set_type_form(action = nil)
 
   action = 'submit_create_pack_material_step1' if !action
   
   pack_material_type_codes = PackMaterialType.find_by_sql('select distinct pack_material_type_code from pack_material_types').map{|g|[g.pack_material_type_code]}
   #pack_material_type_codes.unshift("<empty>")
   
   combos_js = gen_combos_clear_js_for_combos(["pack_material_type_pack_material_type_code","pack_material_type_pack_material_type_code"])
   
  pack_type_observer  = {:updated_field_id => "pack_material_sub_type_code_cell",
					 :remote_method => 'pack_material_type_code_changed',
					 :on_completed_js => combos_js["pack_material_type_pack_material_type_code"]}
					 
   field_configs = Array.new
   
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'pack_material_type_code',
						:settings => {:list => pack_material_type_codes},
						:observer => pack_type_observer}
	
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'pack_material_sub_type_code',
						:settings => {:list => ["select a value from pack material type"]}}
											
	
    build_form(nil,field_configs,action,'pack_material_type','select type')
    
 
 end
 
 def build_configure_pack_material_form(config,type,subtype)
 
   list = {"include" => 1,"require" => 2,"exclude" => 0,}
   
   css_to_use = "blue_label_field"
   css_to_use = "red_label_field" if config.new_record?
   
  field_configs = Array.new
	
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'group_menu', :settings => 
						 {:static_value => "type: " + type + "<br>subtype: " + subtype,:is_separator => false,:css_class => css_to_use}}
						 
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'variant',
						:settings => {:list => list}}	
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'marketing_variety_code',
						:settings => {:list => list}}
						
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'basic_pack_code',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'old_pack_code',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'fruit_mass_nett',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'market_major',
						:settings => {:list => list}}
	
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'dimension_length_mm',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'dimension_width_mm',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'dimension_height_mm',
						:settings => {:list => list}}	
	
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'dimension_thickness_mm',
						:settings => {:list => list}}	
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'assembly_type',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'product_alternative',
						:settings => {:list => list}}
						
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'product_co_use',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'style',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'holes',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'perforation',
						:settings => {:list => list}}
	
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'product_specs_image_url',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'dimension_diameter_mm',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'dimension_thickness_mic',
						:settings => {:list => list}}	
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'material_color',
						:settings => {:list => list}}	
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'material_grade',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'material_mass',
						:settings => {:list => list}}
						
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'material_treatment',
						:settings => {:list => list}}
					
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'material_specs_notes',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'artwork_commodity',
						:settings => {:list => list}}
	
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'artwork_marketing_variety_group',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'artwork_variety',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'artwork_nett_mass',
						:settings => {:list => list}}
							
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'artwork_brand',
						:settings => {:list => list}}	
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'artwork_class',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'artwork_plu_number',
						:settings => {:list => list}}
						
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'artwork_other',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'artwork_image_url',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'marketer',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'retailer',
						:settings => {:list => list}}
	
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'supplier',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'supplier_stock_code',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'ownership',
						:settings => {:list => list}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'material_type',
						:settings => {:list => list}}	
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'consignment_stock',
						:settings => {:list => list}}	
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'pls_pack_code',
						:settings => {:list => list}}				

	
	build_form(config,field_configs,'save_pack_material_config','pm_config','save')
  
 
 end
 
 def build_pack_material_product_form(pack_material_product,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:pack_material_product_form]= Hash.new
#	pack_material_type_codes = PackMaterialType.find_by_sql('select distinct pack_material_type_code from pack_material_types').map{|g|[g.pack_material_type_code]}
#	pack_material_type_codes.unshift("<empty>")
	
	
	#generate javascript for the on_complete ajax event for each combo for fk table: marketing_varieties
	combos_js_for_marketing_varieties = gen_combos_clear_js_for_combos(["pack_material_product_commodity_group_code","pack_material_product_commodity_code","pack_material_product_marketing_variety_code"])
	#Observers for combos representing the key fields of fkey table: marketing_variety_id
	
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'pack_material_product_commodity_group_code_changed',
					 :on_completed_js => combos_js_for_marketing_varieties ["pack_material_product_commodity_group_code"]}

	session[:pack_material_product_form][:commodity_group_code_observer] = commodity_group_code_observer

	commodity_code_observer  = {:updated_field_id => "marketing_variety_code_cell",
					 :remote_method => 'pack_material_product_commodity_code_changed',
					 :on_completed_js => combos_js_for_marketing_varieties ["pack_material_product_commodity_code"]}

	session[:pack_material_product_form][:commodity_code_observer] = commodity_code_observer

   # orgs lists
    marketing_org_codes = Organization.get_all_by_role("MARKETER")
    marketing_org_codes.unshift("<empty>")
    retailer_org_codes = Organization.get_all_by_role("RETAILER")
    retailer_org_codes.unshift("<empty>")
    intaker_org_codes = Organization.get_all_by_role("SUPPLIER")
    intaker_org_codes.unshift("<empty>")
    
    
    #product lists
    upc_codes = UnitPackProduct.find(:all).map{|g|[g.unit_pack_product_code]}
    upc_codes.unshift("<empty>")
    
    cpc_codes = CartonPackProduct.find(:all).map{|g|[g.carton_pack_product_code]}
    cpc_codes.unshift("<empty>")

   #	combo lists for table: marketing_varieties

	commodity_group_codes = nil 
	commodity_codes = nil 
	marketing_variety_codes = nil 
	
	
 
    basic_packs = BasicPack.find_by_sql('select distinct basic_pack_code from basic_packs').map{|g|[g.basic_pack_code]}
	basic_packs.unshift("<empty>")
	
	old_packs = OldPack.find_by_sql('select distinct old_pack_code from old_packs').map{|g|[g.old_pack_code]}
	old_packs.unshift("<empty>")
	
	commodity_group_codes = PackMaterialProduct.get_all_commodity_group_codes
	commodity_group_codes.unshift("<empty>")
	if pack_material_product == nil||is_create_retry
		 commodity_codes = ["Select a value from commodity_group_code"]
		 marketing_variety_codes = ["Select a value from commodity_code"]
		 pack_material_product = PackMaterialProduct.new
		 pack_material_product.pack_material_type_code = session[:new_selected_type_code]
		  pack_material_product.pack_material_sub_type_code = session[:new_selected_sub_type_code]
	else
	    
		commodity_codes = PackMaterialProduct.commodity_codes_for_commodity_group_code(pack_material_product.commodity_group_code)
		marketing_variety_codes = PackMaterialProduct.marketing_variety_codes_for_commodity_code_and_commodity_group_code(pack_material_product.commodity_code, pack_material_product.commodity_group_code)
	end
	
	type_id = PackMaterialType.find_by_pack_material_type_code(pack_material_product.pack_material_type_code).id
	if type_id
	 pack_material_subtype_codes = PackMaterialSubType.find_all_by_pack_material_type_id(type_id).map{|g|[g.pack_material_subtype_code]}
    else
      pack_material_subtype_codes = ["<empty>"]
    end
    
    	query = "SELECT 
             public.pack_material_products.pack_material_product_code
             FROM
             public.pack_material_sub_types
             INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
             INNER JOIN public.pack_material_products ON (public.pack_material_sub_types.id = public.pack_material_products.pack_material_sub_type_id)
             WHERE
            (public.pack_material_types.pack_material_type_code = '#{pack_material_product.pack_material_type_code}') AND 
            (public.pack_material_sub_types.pack_material_subtype_code = '#{pack_material_product.pack_material_sub_type_code}')"
	
	
	pack_products = PackMaterialProduct.find_by_sql(query).map{|b|b.pack_material_product_code}
	pack_products.delete(pack_material_product.pack_material_product_code)if pack_material_product.pack_material_product_code
	pack_products.unshift("<empty>")
	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	 
	 query = "SELECT 
            public.pack_material_sub_types.id
            FROM
            public.pack_material_sub_types
            INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
            WHERE
           (public.pack_material_types.pack_material_type_code = '#{pack_material_product.pack_material_type_code}' and 
            public.pack_material_sub_types.pack_material_subtype_code = '#{pack_material_product.pack_material_sub_type_code}')"
      
	  sub_id =PackMaterialSubType.find_by_sql(query).map{|t|[t.id]}[0]
	  
	 config = PackMaterialProductConfig.find_by_pack_material_sub_type_id(sub_id)
    
     if config == nil
     
      raise "You have not yet defined a configuration record for type: '#{pack_material_product.pack_material_type_code}' and subtype:  '#{pack_material_product.pack_material_sub_type_code}'"
     end
     
     if pack_material_product == nil||is_create_retry
		 commodity_codes = ["Select a value from commodity_group_code"]
		 marketing_variety_codes = ["Select a value from commodity_code"]
		 pack_material_product = PackMaterialProduct.new
		 pack_material_product.pack_material_type_code = session[:new_selected_type_code]
		  pack_material_product.pack_material_sub_type_code = session[:new_selected_sub_type_code]
	else
	    if pack_material_product.commodity_group_code
		  commodity_codes = PackMaterialProduct.commodity_codes_for_commodity_group_code(pack_material_product.commodity_group_code)
		end
		if pack_material_product.commodity_code
		  marketing_variety_codes = PackMaterialProduct.marketing_variety_codes_for_commodity_code_and_commodity_group_code(pack_material_product.commodity_code, pack_material_product.commodity_group_code)
	    end
	end
	
   #-------------
   #GLOBAL FIELDS
   #-------------
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'pack_material_product_code?required'}
    
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'inventory_code'}
						
   #----------------------------------------------------------------------------------------------------
   #Combo field to represent foreign key (pack_material_group_id) on related table: pack_material_groups
   #-----------------------------------------------------------------------------------------------------
#	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
#						:field_name => 'pack_material_type_code',
#						:settings => {:list => pack_material_type_codes}}

   field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'pack_material_type_code',
						:settings => {:css_class => "blue_border_label_field"}}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'pack_material_sub_type_code',
						:settings => {:css_class => "blue_border_label_field"}}

    group_menu = "collapse all <img src = '/images/collapse_groups.png' onclick = 'collapse_all();' </img>&nbsp;&nbsp;&nbsp;expand all<img src = '/images/expand_groups.png' onclick = 'expand_all();' </img>"
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'group_menu', :settings => 
						 {:static_value => group_menu,:is_separator => false,:css_class => 'blue_label_field'}}
   #----------------------------
   #FIELDS GROUP: CLASSIFICATION
   #----------------------------
   if ( config.variant && config.variant > 0) ||( config.style && config.style > 0) ||( config.assembly_type && config.assembly_type > 0 )||( config.market_major && config.market_major > 0) || ( config.commodity_code && config.commodity_code > 0)||( config.marketing_variety_code && config.marketing_variety_code > 0)||(config.basic_pack_code && config.basic_pack_code > 0) ||( config.old_pack_code && config.old_pack_code > 0)||( config.fruit_mass_nett && config.fruit_mass_nett > 0)||( config.holes && config.holes > 0)||( config.perforation && config.perforation > 0)||( config.product_specs_image_url && config.product_specs_image_url > 0 )
   
     field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'classification', :settings => 
						 {:static_value => 'CLASSIFICATION',:is_separator => true}}
						
   end			
   		
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'variant'} if config.variant &&  config.variant > 0
   
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'style'} if config.style &&  config.style > 0

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'assembly_type'} if config.assembly_type &&  config.assembly_type > 0
    
    
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'market_major'} if config.market_major &&  config.market_major > 0
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (marketing_variety_id) on related table: marketing_varieties
#	----------------------------------------------------------------------------------------------
	if config.commodity_code && config.commodity_code  > 0 
	     field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	     field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes}}
						
		if config.marketing_variety_code
		 
		  field_configs[field_configs.length() - 1 ][:settings][:observer]= commodity_code_observer
 
	      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'marketing_variety_code',
						:settings => {:list => marketing_variety_codes}}
						
		end
	
	end
 
     if config.basic_pack_code && config.basic_pack_code > 0
	  field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'basic_pack_code',
						:settings => {:list => basic_packs}}
	 end

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'old_pack_code',
						:settings => {:list => old_packs}} if config.old_pack_code &&  config.old_pack_code > 0
						
	if pack_material_product.pack_material_type_code == "RU" && config.pls_pack_code && config.pls_pack_code > 0
         field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'unit_pack_product_code',
						:settings => {:list => upc_codes}}
						
		if config.pls_pack_code == 2
		  field_configs[field_configs.length() -1 ][:field_name]+= "?required"
		end
   end
   
   if pack_material_product.pack_material_type_code == "TU"
         field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'carton_pack_product_code?required',
						:settings => {:list => cpc_codes}}
   end
   

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'fruit_mass_nett'}if config.fruit_mass_nett &&  config.fruit_mass_nett > 0

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'holes'}if config.holes &&  config.holes > 0
   
   field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'perforation'}if config.perforation &&  config.perforation > 0	
											
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'product_specs_image_url'}if config.product_specs_image_url &&  config.product_specs_image_url > 0
   
   #-----------------------
   #FIELDS GROUP: DIMENSION
   #-----------------------
    if ( config.dimension_length_mm && config.dimension_length_mm > 0) ||( config.dimension_width_mm && config.dimension_width_mm > 0) ||( config.dimension_height_mm && config.dimension_height_mm > 0 )||( config.dimension_diameter_mm && config.dimension_diameter_mm > 0) || ( config.dimension_thickness_mm && config.dimension_thickness_mm > 0)||( config.dimension_thickness_mic && config.dimension_thickness_mic > 0)
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'dimension', :settings => 
						 {:static_value => 'DIMENSION',:is_separator => true}}
   
   end
   
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'dimension_length_mm'} if config.dimension_length_mm &&  config.dimension_length_mm > 0

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'dimension_width_mm'} if config.dimension_width_mm &&  config.dimension_width_mm > 0

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'dimension_height_mm'}if config.dimension_height_mm &&  config.dimension_height_mm > 0

    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'dimension_diameter_mm'}if config.dimension_diameter_mm &&  config.dimension_diameter_mm > 0
						
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'dimension_thickness_mm'}if config.dimension_thickness_mm &&  config.dimension_thickness_mm > 0

    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'dimension_thickness_mic'}if config.dimension_thickness_mic &&  config.dimension_thickness_mic > 0


   #-----------------------
   #FIELDS GROUP: MATERIAL
   #-----------------------
   if ( config.material_color && config.material_color > 0) ||( config.material_grade && config.material_grade > 0) ||( config.material_mass && config.material_mass > 0 )||( config.material_type && config.material_type > 0) || ( config.material_treatment && config.material_treatment > 0)||( config.material_specs_notes && config.material_specs_notes > 0)
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'material', :settings => 
						 {:static_value => 'MATERIAL',:is_separator => true}}

   end
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'material_color'}if config.material_color &&  config.material_color > 0
	
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'material_grade'}if config.material_grade &&  config.material_grade > 0	
										
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'material_mass'}if config.material_mass &&  config.material_mass > 0	
    
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'material_type'}if config.material_type &&  config.material_type > 0	
	

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'material_treatment'}if config.material_treatment &&  config.material_treatment > 0	

    
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'material_specs_notes'} if config.material_specs_notes &&  config.material_specs_notes > 0
    
   #-----------------------
   #FIELDS GROUP: ARTWORK
   #-----------------------
   if ( config.artwork_commodity && config.artwork_commodity > 0) ||( config.artwork_marketing_variety_group && config.artwork_marketing_variety_group > 0) ||( config.artwork_variety && config.artwork_variety > 0 )||( config.artwork_nett_mass && config.artwork_nett_mass > 0) || ( config.artwork_brand && config.artwork_brand > 0)||( config.artwork_class && config.artwork_class > 0)||(config.artwork_plu_number && config.artwork_plu_number > 0) ||( config.artwork_other && config.artwork_other > 0)||( config.artwork_image_url && config.artwork_image_url > 0)
     field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'artwork', :settings => 
						 {:static_value => 'ARTWORK',:is_separator => true}}
   end
    
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'artwork_commodity'}if config.artwork_commodity &&  config.artwork_commodity > 0	
    
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'artwork_marketing_variety_group'}if config.artwork_marketing_variety_group &&  config.artwork_marketing_variety_group > 0	
    
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'artwork_variety'}if config.artwork_variety &&  config.artwork_variety > 0	
    
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'artwork_nett_mass'}if config.artwork_nett_mass &&  config.artwork_nett_mass > 0	
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'artwork_brand'}if config.artwork_brand &&  config.artwork_brand > 0
								
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'artwork_class'}if config.artwork_class &&  config.artwork_class > 0
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'artwork_plu_number'}if config.artwork_plu_number &&  config.artwork_plu_number > 0
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'artwork_other'}if config.artwork_other &&  config.artwork_other > 0
						
											
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'artwork_image_url'}if config.artwork_image_url &&  config.artwork_image_url > 0
	
						
   #-----------------------
   #FIELDS GROUP: ORGS
   #-----------------------
   if ( config.marketer && config.marketer > 0) ||( config.retailer && config.retailer > 0) ||( config.supplier && config.supplier > 0 )||( config.supplier_stock_code && config.supplier_stock_code > 0)
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'orgs', :settings => 
						 {:static_value => 'ORGS',:is_separator => true}}
   end					
	
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'marketer',
						:settings => {:list => marketing_org_codes}} if config.marketer &&  config.marketer > 0
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'retailer',
						:settings => {:list => retailer_org_codes}} if config.retailer &&  config.retailer > 0
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'supplier',
						:settings => {:list => intaker_org_codes}}if config.supplier &&  config.supplier > 0
	
	
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'supplier_stock_code'} if config.supplier_stock_code &&  config.supplier_stock_code > 0
	
	
   #----------------------------------
   #FIELDS GROUP: INVENTORY MANAGEMENT
   #----------------------------------
   
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'inventory_management', :settings => 
						 {:static_value => 'INVENTORY_MANAGEMENT',:is_separator => true}}
  
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'product_alternative',
						:settings => {:list => pack_products}} if config.product_alternative &&  config.product_alternative > 0 

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'product_co_use',
						:settings => {:list => pack_products}} if config.product_co_use &&  config.product_co_use > 0 
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'ownership'}if config.ownership &&  config.ownership > 0 
    
    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'consignment_stock?required'}if config.consignment_stock &&  config.consignment_stock > 0 
						
	field_configs[field_configs.length()] = {:field_type => 'DateField',
						:field_name => 'start_date?required'} 
	
	field_configs[field_configs.length()] = {:field_type => 'DateField',
						:field_name => 'end_date?required'}
	
    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'active?required'}
						
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'remarks'}

	#set required markers
	field_configs.each do |field_config|
	  if config.has_attribute?(field_config[:field_name])
	   if config.attributes[field_config[:field_name]] && config.attributes[field_config[:field_name]] == 2
	     field_config[:field_name]+= "?required"
	   end
	  end
	
	end								
 
	build_form(pack_material_product,field_configs,action,'pack_material_product',caption,is_edit)

end
 
 
 def build_pack_material_product_search_form(pack_material_product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:pack_material_product_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["pack_material_product_pack_material_type_code","pack_material_product_pack_material_product_code"])
	#Observers for search combos
	pack_material_type_code_observer  = {:updated_field_id => "pack_material_product_code_cell",
					 :remote_method => 'pack_material_product_pack_material_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["pack_material_product_pack_material_type_code"]}

	session[:pack_material_product_search_form][:pack_material_type_code_observer] = pack_material_type_code_observer

 
	pack_material_type_codes = PackMaterialProduct.find_by_sql('select distinct pack_material_type_code from pack_material_products').map{|g|[g.pack_material_type_code]}
	pack_material_type_codes.unshift("<empty>")
	if is_flat_search
		pack_material_product_codes = PackMaterialProduct.find_by_sql('select distinct pack_material_product_code from pack_material_products').map{|g|[g.pack_material_product_code]}
		pack_material_product_codes.unshift("<empty>")
		pack_material_type_code_observer = nil
	else
		 pack_material_product_codes = ["Select a value from pack_material_type_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'pack_material_type_code',
						:settings => {:list => pack_material_type_codes},
						:observer => pack_material_type_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'pack_material_product_code',
						:settings => {:list => pack_material_product_codes}}
 
	build_form(pack_material_product,field_configs,action,'pack_material_product',caption,false)

end



 def build_pack_material_product_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pack_material_product_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pack_material_type_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pack_material_sub_type_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'unit_pack_product_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'carton_pack_product_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'marketing_variety_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'basic_pack_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'old_pack_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'fruit_mass_nett'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'market_major'}
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'start_date'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'end_date'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'consignment_stock'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'active'}
	
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'dimension_length_mm'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'dimension_width_mm'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'dimension_height_mm'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'dimension_thickness_mm'}
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'remarks'}
	
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit pack_material_product',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_pack_material_product',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete pack_material_product',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_pack_material_product',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
