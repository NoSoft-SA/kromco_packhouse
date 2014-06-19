module Products::RmtProductHelper
 
 def build_rmt_product_type_select_form(action,caption)

   @rmt_product_types = RmtProductType.find(:all,:select=>"distinct rmt_product_type_code").map{|r| [r.rmt_product_type_code]}
  field_configs = Array.new
  
  field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_product_type',
						:settings => {:list => @rmt_product_types}}
  
  build_form(nil,field_configs,action,'rmt_product',caption)
 
 end
 
 
 def build_rmt_product_form(rmt_product,action,caption,is_edit = nil,is_create_retry = nil,is_orchard_run =nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:rmt_product_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: varieties
	combos_js_for_varieties = gen_combos_clear_js_for_combos(["rmt_product_commodity_group_code","rmt_product_commodity_code","rmt_product_variety_code"])
	#Observers for combos representing the key fields of fkey table: variety_id
	size_codes = Size.find_by_sql('select distinct size_code from sizes').map{|g|[g.size_code]}
  if(session[:rmt_product_type].to_s.upcase=='PRESORT')
    treatment_type = 'PRESORT'
  elsif(session[:rmt_product_type].to_s.upcase=='ORCHARD_RUN')
    treatment_type = "PRE_HARVEST"
  elsif(session[:rmt_product_type].to_s.upcase=='REBIN')
    treatment_type = "PACKHOUSE"
  end

	treatment_codes = Treatment.find_by_sql("select distinct treatment_code from treatments where treatment_type_code = '#{treatment_type}'").map{|g|[g.treatment_code]}
	
	treatment_codes.unshift("<empty>")
	ripe_point_codes = RipePoint.find_by_sql('select distinct ripe_point_code from ripe_points').map{|g|[g.ripe_point_code]}
	
	product_class_codes = ProductClass.find_by_sql('select distinct product_class_code from product_classes').map{|g|[g.product_class_code]}
	
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'rmt_product_commodity_group_code_changed',
					 :on_completed_js => combos_js_for_varieties ["rmt_product_commodity_group_code"]}

	session[:rmt_product_form][:commodity_group_code_observer] = commodity_group_code_observer

	commodity_code_observer  = {:updated_field_id => "variety_code_cell",
					 :remote_method => 'rmt_product_commodity_code_changed',
					 :on_completed_js => combos_js_for_varieties ["rmt_product_commodity_code"]}
	

	ripe_point_js = "\n img = document.getElementById('img_rmt_product_ripe_point_code');"
	ripe_point_js += "\n if(img != null)img.style.display = 'none';"
	
	
	ripe_point_observer  = {:updated_field_id => "ripe_point_description_cell",
					 :remote_method => 'rmt_product_ripe_point_changed',
					 :on_completed_js => ripe_point_js}

	session[:rmt_product_form][:commodity_code_observer] = commodity_code_observer

#	combo lists for table: varieties

	commodity_group_codes = nil 
	commodity_codes = nil 
	variety_codes = nil 
 
	commodity_group_codes = RmtProduct.get_all_commodity_group_codes
	commodity_group_codes.unshift "<empty>"
	
	if rmt_product == nil||is_create_retry
		 commodity_codes = ["Select a value from commodity_group_code"]
		 variety_codes = ["Select a value from commodity_code"]
	else
		#commodity_codes = RmtProduct.commodity_codes_for_commodity_group_code(rmt_product.variety.commodity_group_code)
		commodity_codes = RmtProduct.find_by_sql("Select distinct commodity_code from rmt_products where commodity_group_code = '#{rmt_product.commodity_group_code}'").map{|g|[g.commodity_code]}
		if rmt_product.rmt_product_type_code == "orchard_run"||rmt_product.rmt_product_type_code == "presort"
		   
	       variety_codes = Variety.find_by_sql("Select distinct rmt_variety_code as variety_code from varieties where commodity_code = '#{rmt_product.commodity_code}' and commodity_group_code = '#{rmt_product.commodity_group_code}'").map{|g|[g.variety_code]}
	       
	    else
	       variety_codes = Variety.find_by_sql("Select distinct marketing_variety_code as variety_code from varieties where commodity_code = '#{rmt_product.commodity_code}' and commodity_group_code = '#{rmt_product.commodity_group_code}'").map{|g|[g.variety_code]}
	   end
		
	end
	
    if(session[:rmt_product_type].to_s.upcase=='REBIN')
      query = "SELECT 
             public.pack_material_products.pack_material_product_code
             FROM
             public.pack_material_sub_types
             INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
             INNER JOIN public.pack_material_products ON (public.pack_material_sub_types.id = public.pack_material_products.pack_material_sub_type_id)
             WHERE
            (public.pack_material_types.pack_material_type_code = 'RMU')"
	
	
	  bin_types = PackMaterialProduct.find_by_sql(query).map{|b|b.pack_material_product_code}
    
    
    end
    
    
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
    field_configs[0] = {:field_type => 'LabelField',
                        :field_name => 'rmt_product_code'}
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (variety_id) on related table: varieties
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
						:field_name => 'variety_code',
						:settings => {:list => variety_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (treatment_id) on related table: treatments
#	----------------------------------------------------------------------------------------------
	rmt_product = RmtProduct.new #needed only to set default values
	
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_code',
						:settings => {:list => treatment_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (product_class_id) on related table: product_classes
#	----------------------------------------------------------------------------------------------
	if session[:rmt_product_type]== "orchard_run"
	   
	   rmt_product.product_class_code = "OR"
	   field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'product_class_code'}
	else
						
	   field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'product_class_code',
						:settings => {:list => product_class_codes}}
						
	
	end
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (ripe_point_id) on related table: ripe_points
#	----------------------------------------------------------------------------------------------
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'ripe_point_code',
						:settings => {:list => ripe_point_codes},
						:observer => ripe_point_observer}
 
    field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'ripe_point_description'}
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (size_id) on related table: sizes
#	----------------------------------------------------------------------------------------------

	if session[:rmt_product_type]== "rebin"
	  field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'size_code',
						:settings => {:list => size_codes}}
	 
	 
	 field_configs[9] =  {:field_type => 'DropDownField',
						:field_name => 'bin_type',
						:settings => {:list => bin_types}}
						
	elsif session[:rmt_product_type]== "presort"	
		field_configs[8] =  {:field_type => 'DropDownField',
							:field_name => 'size_code',
							:settings => {:list => size_codes}}
	 
	end
	build_form(rmt_product,field_configs,action,'rmt_product',caption,is_edit)

end
 
 
 def build_rmt_product_search_form(rmt_product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:rmt_product_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["rmt_product_commodity_group_code","rmt_product_commodity_code","rmt_product_variety_code","rmt_product_size_code","rmt_product_product_class_code","rmt_product_ripe_point_code","rmt_product_treatment_code"])
	#Observers for search combos
	commodity_group_code_observer  = {:updated_field_id => "commodity_code_cell",
					 :remote_method => 'rmt_product_commodity_group_code_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_product_commodity_group_code"]}

	session[:rmt_product_search_form][:commodity_group_code_observer] = commodity_group_code_observer

	commodity_code_observer  = {:updated_field_id => "variety_code_cell",
					 :remote_method => 'rmt_product_commodity_code_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_product_commodity_code"]}

	session[:rmt_product_search_form][:commodity_code_observer] = commodity_code_observer

	variety_code_observer  = {:updated_field_id => "size_code_cell",
					 :remote_method => 'rmt_product_variety_code_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_product_variety_code"]}

	session[:rmt_product_search_form][:variety_code_observer] = variety_code_observer

	size_code_observer  = {:updated_field_id => "product_class_code_cell",
					 :remote_method => 'rmt_product_size_code_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_product_size_code"]}

	session[:rmt_product_search_form][:size_code_observer] = size_code_observer

	product_class_code_observer  = {:updated_field_id => "ripe_point_code_cell",
					 :remote_method => 'rmt_product_product_class_code_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_product_product_class_code"]}

	session[:rmt_product_search_form][:product_class_code_observer] = product_class_code_observer

	ripe_point_code_observer  = {:updated_field_id => "treatment_code_cell",
					 :remote_method => 'rmt_product_ripe_point_code_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_product_ripe_point_code"]}

	session[:rmt_product_search_form][:ripe_point_code_observer] = ripe_point_code_observer

 
	commodity_group_codes = RmtProduct.find_by_sql('select distinct commodity_group_code from rmt_products').map{|g|[g.commodity_group_code]}
	commodity_group_codes.unshift("<empty>")
	if is_flat_search
		commodity_codes = RmtProduct.find_by_sql('select distinct commodity_code from rmt_products').map{|g|[g.commodity_code]}
		commodity_codes.unshift("<empty>")
		variety_codes = RmtProduct.find_by_sql('select distinct variety_code from rmt_products').map{|g|[g.variety_code]}
		variety_codes.unshift("<empty>")
		size_codes = RmtProduct.find_by_sql('select distinct size_code from rmt_products').map{|g|[g.size_code]}
		size_codes.unshift("<empty>")
		product_class_codes = RmtProduct.find_by_sql('select distinct product_class_code from rmt_products').map{|g|[g.product_class_code]}
		product_class_codes.unshift("<empty>")
		ripe_point_codes = RmtProduct.find_by_sql('select distinct ripe_point_code from rmt_products').map{|g|[g.ripe_point_code]}
		ripe_point_codes.unshift("<empty>")
		treatment_codes = RmtProduct.find_by_sql('select distinct treatment_code from rmt_products').map{|g|[g.treatment_code]}
		treatment_codes.unshift("<empty>")
		commodity_group_code_observer = nil
		commodity_code_observer = nil
		variety_code_observer = nil
		size_code_observer = nil
		product_class_code_observer = nil
		ripe_point_code_observer = nil
	else
		 commodity_codes = ["Select a value from commodity_group_code"]
		 variety_codes = ["Select a value from commodity_code"]
		 size_codes = ["Select a value from variety_code"]
		 product_class_codes = ["Select a value from size_code"]
		 ripe_point_codes = ["Select a value from product_class_code"]
		 treatment_codes = ["Select a value from ripe_point_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_group_code',
						:settings => {:list => commodity_group_codes},
						:observer => commodity_group_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'variety_code',
						:settings => {:list => variety_codes},
						:observer => variety_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'size_code',
						:settings => {:list => size_codes},
						:observer => size_code_observer}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'product_class_code',
						:settings => {:list => product_class_codes},
						:observer => product_class_code_observer}
 
	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'ripe_point_code',
						:settings => {:list => ripe_point_codes},
						:observer => ripe_point_code_observer}
    
   
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_code',
						:settings => {:list => treatment_codes}}
 
	build_form(rmt_product,field_configs,action,'rmt_product',caption,false)

end

def build_rmt_product_view(rmt_product)

   field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'rmt_product_type_code'}
						
	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'rmt_product_code'}
						
	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'commodity_group_code'}
 
	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'commodity_code'}
 
	field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'variety_code'}
 
	field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'size_code'}
 
	field_configs[6] =  {:field_type => 'LabelField',
						:field_name => 'product_class_code'}
 
	field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'ripe_point_code'}
    
    field_configs[8] =  {:field_type => 'LabelField',
						:field_name => 'ripe_point_description'}
						
						
	field_configs[9] =  {:field_type => 'LabelField',
						:field_name => 'treatment_code'}
 
	build_form(rmt_product,field_configs,"view_paging_handler",'rmt_product',"back")

end

 def build_rmt_product_grid(data_set,can_edit,can_delete,is_for_rmt_setup = nil,can_setup = nil)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'rmt_product_type_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'rmt_product_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'commodity_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'variety_code'}
	column_configs[4] = {:field_type => 'text',:field_name => 'treatment_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'product_class_code'}
	column_configs[6] = {:field_type => 'text',:field_name => 'ripe_point_code'}
	column_configs[7] = {:field_type => 'text',:field_name => 'size_code'}
	column_configs[8] = {:field_type => 'text',:field_name => 'commodity_group_code'}
#	----------------------
#	define action columns
#	----------------------
    
    #this is for the 'product' context
    if ! is_for_rmt_setup

		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view rmt_product',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_rmt_product',
				:id_column => 'id'}}
#	 end
	elsif can_setup
	  column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'setup_rmt_product',
			:settings => 
				 {:link_text => 'setup rmt product',
				:target_action => 'setup_new_rmt_product',
				:id_column => 'id'}} 
	
	end
	
 return get_data_grid(data_set,column_configs)
end

end
