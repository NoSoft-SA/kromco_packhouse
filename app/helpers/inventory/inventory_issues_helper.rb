module Inventory::InventoryIssuesHelper

    def build_inventory_issue_form(inventory_issue,action,caption, is_edit=nil,is_create_retry=nil)
      #--------------------------------------------------------------------------------------------------
      #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
      #	in a composite foreign key
      #--------------------------------------------------------------------------------------------------
	  session[:inventory_issue_form]= Hash.new
	  
	  #generate javascript for the on_complete ajax event for each combo
	  search_combos_js_for_pack_material = gen_combos_clear_js_for_combos(["inventory_issue_pack_material_type_code", "inventory_issue_pack_material_sub_type_code","inventory_issue_pack_material_product_code"])
	  #Observers for search combos
	  
	  on_complete_js_party_type_name = "\n img = document.getElementById('img_inventory_issue_party_type_name');"
	  on_complete_js_party_type_name += "\n if(img != null) img.style.display = 'none';"
	  
	  party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'inventory_issue_party_type_name_search_combo_changed',
					 :on_completed_js => on_complete_js_party_type_name}#search_combos_js["parties_role_party_type_name"]}

	  session[:inventory_issue_form][:party_type_name_observer] = party_type_name_observer
	  
	  on_complete_js_party_name = "\n img = document.getElementById('img_inventory_issue_party_name');"
	  on_complete_js_party_name += "\n if(img != null) img.style.display = 'none';"

	  party_name_observer  = {:updated_field_id => "parties_role_name_cell",
					 :remote_method => 'inventory_issue_party_name_search_combo_changed',
					 :on_completed_js => on_complete_js_party_name}

	  session[:inventory_issue_form][:party_name_observer] = party_name_observer
	  
	  pack_material_type_code_observer = {:updated_field_id=>"pack_material_sub_type_code_cell",
	                                      :remote_method=>'inventory_issue_pack_material_type_code_changed',
	                                      :on_completed_js=>search_combos_js_for_pack_material["inventory_issue_pack_material_type_code"]}
	                                     
	  session[:inventory_issue_form][:pack_material_type_code_observer] = pack_material_type_code_observer
	  
	  pack_material_sub_type_code_observer = {:updated_field_id=>"pack_material_product_code_cell",
	                                      :remote_method=>'inventory_issue_pack_material_sub_type_code_changed',
	                                      :on_completed_js=>search_combos_js_for_pack_material["inventory_issue_pack_material_sub_type_code"]}
	                                     
	  session[:inventory_issue_form][:pack_material_sub_type_code_observer] = pack_material_sub_type_code_observer
	  
	  party_type_names = nil 
	  party_names = nil 
	  role_names = nil 
	  
	  pack_material_type_codes = nil
	  pack_material_sub_type_codes = nil
	  pack_material_product_codes = nil
	  
	  farm_codes = nil
	  inventory_issue_type_codes = nil
	  
	  #pack_material_type_codes = PackMaterialType.find_by_sql("select distinct pack_material_type_code from pack_material_types").map{|g|[g.pack_material_type_code]}
	  #pack_material_type_codes.unshift("<empty>")
	  pack_material_type_codes = PackMaterialProduct.find_by_sql("select distinct pack_material_type_code from pack_material_products").map{|g|[g.pack_material_type_code]}
	  pack_material_type_codes.unshift("<empty>")
	  
	  party_type_names = PartiesRole.find_by_sql("select distinct party_type_name from parties").map{|g|[g.party_type_name]}
	  party_type_names.unshift("<empty>")
	  
	  farm_codes = Farm.find_by_sql("select distinct farm_code from farms").map{|g|[g.farm_code]}
	  farm_codes.unshift("<empty>")
	  
	  inventory_issue_type_codes = InventoryIssueType.find_by_sql("select distinct inventory_issue_type_code from inventory_issue_types").map{|g|[g.inventory_issue_type_code]}
	  inventory_issue_type_codes.unshift("<empty>")
	  
	  if inventory_issue == nil || is_create_retry
	     party_names = ["Select a value from party_type_name"]
		 role_names = ["Select a value from party_name"]
		 pack_material_sub_type_codes = ["Select a value from pack_material_type_code"]
		 pack_material_product_codes = ["Select a value from pack_material_subtype_code"]
	  else
	     party_names = PartiesRole.find_by_sql("select distinct party_name from parties").map{|g|[g.party_name]}
	     party_names.unshift("<empty>")
	     role_names = PartiesRole.find_by_sql("select distinct role_name from parties_roles").map{|g|[g.role_name]}
	     role_names.unshift("<empty>")
	     #pack_material_subtype_codes = PackMaterialSubType.find_by_sql("select distinct pack_material_subtype_code from pack_material_sub_types").map{|g|[g.pack_material_subtype_code]}
	     #pack_material_subtype_codes.unshift("<empty>");
	     pack_material_sub_type_codes = PackMaterialProduct.find_by_sql("select distinct pack_material_sub_type_code from pack_material_products").map{|g|[g.pack_material_sub_type_code]}
	     pack_material_sub_type_codes.unshift("<empty>");
	     pack_material_product_codes = PackMaterialProduct.find_by_sql("select distinct pack_material_product_code from pack_material_products").map{|g|[g.pack_material_product_code]}
	     pack_material_product_codes.unshift("<empty>");
	     
	     parties_role = PartiesRole.find_by_id_and_role_name(inventory_issue.parties_role_id, inventory_issue.parties_role_name)
	     if parties_role
	       inventory_issue.party_type_name = parties_role.party_type_name
	       inventory_issue.party_name = parties_role.party_name
	     end
	     
	     pack_material_product = PackMaterialProduct.find_by_id_and_pack_material_product_code(inventory_issue.pack_material_product_id, inventory_issue.pack_material_product_code)
	     if pack_material_product
	       inventory_issue.pack_material_type_code = pack_material_product.pack_material_type_code
	       inventory_issue.pack_material_sub_type_code = pack_material_product.pack_material_sub_type_code
	     end
	  end
	  
	  field_configs = Array.new
	  
	  field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'issue_date_time', :settings => {:date_textfield_id=>'issue_date_time'}}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'inventory_issue_type_code', :settings=>{:list=>inventory_issue_type_codes}}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'reference_number'}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_type_name', :settings=>{:list=>party_type_names}, :observer=>party_type_name_observer}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_name', :settings=>{:list=>party_names}, :observer=>party_name_observer}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'parties_role_name', :settings=>{:list=>role_names}}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'farm_code', :settings=>{:list=>farm_codes}}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'quantity_issued'}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'pack_material_type_code', :settings=>{:list=>pack_material_type_codes}, :observer=>pack_material_type_code_observer}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'pack_material_sub_type_code', :settings=>{:list=>pack_material_sub_type_codes}, :observer=>pack_material_sub_type_code_observer}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'pack_material_product_code', :settings=>{:list=>pack_material_product_codes}}
	  field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'comments'}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'quantity_on_farms_new'}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'truck_code'}
	  
	  #field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'picklist_id'}
	  
	  build_form(inventory_issue,field_configs,action,'inventory_issue',caption,is_edit)
	  
   end
   
   
   def build_inventory_issues_grid(data_set,can_edit,can_delete,issue_lookup)

    	column_configs = Array.new
    	column_configs[0] = {:field_type => 'text',:field_name => 'issue_date_time'}
    	column_configs[10] = {:field_type => 'text',:field_name => 'inventory_issue_type_code'}
    	column_configs[1] = {:field_type => 'text',:field_name => 'party_type_name'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'party_name'}
    	column_configs[3] = {:field_type => 'text',:field_name => 'parties_role_name'}
    	column_configs[4] = {:field_type => 'text',:field_name => 'farm_code'}
    	column_configs[5] = {:field_type => 'text',:field_name => 'quantity_issued'}
    	column_configs[6] = {:field_type => 'text',:field_name => 'pack_material_product_code'}
    	column_configs[7] = {:field_type => 'text',:field_name => 'comments'}
    	column_configs[8] = {:field_type => 'text',:field_name => 'quantity_on_farms_new'}
    	column_configs[9] = {:field_type => 'text',:field_name => 'truck_code'}
    	#column_configs[10] = {:field_type => 'text',:field_name => 'picklist_id'}
    	column_configs[10] = {:field_type => 'text',:field_name => 'reference_number'}
    	
      #	----------------------
      #	define action columns
      #	----------------------
      if issue_lookup
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'select issue',
        			:settings =>
        				 {:link_text => 'select',
        				:target_action => 'select_inventory_issue',
        				:id_column => 'id'}}
      else
      	if can_edit
      		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit issue',
      			:settings => 
      				 {:link_text => 'edit',
      				:target_action => 'edit_inventory_issue',
      				:id_column => 'id'}}
      	end
      
      	if can_delete
      		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete issue',
      			:settings => 
      				 {:link_text => 'delete',
      				:target_action => 'delete_inventory_issue',
      				:id_column => 'id'}}
      	end
      end
      	
       return get_data_grid(data_set,column_configs)
   end
   
   
   def build_inventory_issue_search_form(inventory_issue,action,caption,is_flat_search=nil)
      #	--------------------------------------------------------------------------------------------------
      #	Define an observer for each index field
      #	--------------------------------------------------------------------------------------------------
      	session[:inventory_issue_search_form]= Hash.new 
      	#generate javascript for the on_complete ajax event for each combo
      	search_combos_js = gen_combos_clear_js_for_combos(["inventory_issue_inventory_issue_type_code","inventory_issue_reference_number","inventory_issue_farm_code","inventory_issue_truck_code"])
      	#Observers for search combos
      	inventory_issue_type_code_observer  = {:updated_field_id => "reference_number_cell",
      					 :remote_method => 'inventory_issue_inventory_issue_type_code_search_combo_changed',
      					 :on_completed_js => search_combos_js["inventory_issue_inventory_issue_type_code"]}
      					 
          session[:inventory_issue_search_form][:inventory_issue_type_code_observer] = inventory_issue_type_code_observer
          
          reference_number_observer = {:updated_field_id => "farm_code_cell",
                           :remote_method => 'inventory_issue_reference_number_search_combo_changed',
                           :on_completed_js => search_combos_js["inventory_issue_reference_number"]}
                           
          session[:inventory_issue_search_form][:reference_number_observer] = reference_number_observer
          
          farm_code_observer = {:updated_field_id => "truck_code_cell",
                            :remote_method => 'inventory_issue_farm_code_search_combo_changed',
                            :on_completed_js => search_combos_js["inventory_issue_farm_code"]}
                            
          session[:inventory_issue_search_form][:farm_code_observer] = farm_code_observer
          
          inventory_issue_type_codes = InventoryIssue.find_by_sql("select distinct inventory_issue_type_code from inventory_issues").map{|g|[g.inventory_issue_type_code]}
          inventory_issue_type_codes.unshift("<empty>")
          if is_flat_search
             reference_numbers = InventoryIssue.find_by_sql("select distinct reference_number from inventory_issues").map{|g|[g.reference_number]}
             reference_numbers.unshift("<empty>")
             farm_codes = InventoryIssue.find_by_sql("select distinct farm_code from inventory_issues").map{|g|[g.farm_code]}
             farm_codes.unshift("<empty>")
             truck_codes = InventoryIssue.find_by_sql("select distinct truck_code from inventory_issues").map{|g|[g.truck_code]}
             truck_codes.unshift("<empty>")
             inventory_issue_type_code_observer = nil
             reference_number_observer = nil
             farm_code_observer = nil
          else
             reference_numbers = ["select a value from inventory_issue_type_code"]
             farm_codes = ["select a value from reference_number"]
             truck_codes =["select a value from farm_code"]
          end
          
          #	----------------------------------------
          #	 Define search fields to build form from
          #	----------------------------------------
          	 field_configs = Array.new
          #	----------------------------------------------------------------------------------------------
          #	Define search Combo fields to represent the unique index on this table 
          #	----------------------------------------------------------------------------------------------
      	  field_configs[0] =  {:field_type => 'DropDownField',
      						:field_name => 'inventory_issue_type_code',
      						:settings => {:list => inventory_issue_type_codes},
      						:observer => inventory_issue_type_code_observer}
       
      	  field_configs[1] =  {:field_type => 'DropDownField',
      						:field_name => 'reference_number',
      						:settings => {:list => reference_numbers},
      						:observer => reference_number_observer}
       
      	  field_configs[2] =  {:field_type => 'DropDownField',
      						:field_name => 'farm_code',
      						:settings => {:list => farm_codes},
      						:observer => farm_code_observer}
       
      	  field_configs[3] =  {:field_type => 'DropDownField',
      						:field_name => 'truck_code',
      						:settings => {:list => truck_codes}}
      	
      	build_form(inventory_issue,field_configs,action,'inventory_issue',caption,false)
          
   end

end