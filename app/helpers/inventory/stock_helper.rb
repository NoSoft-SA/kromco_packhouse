module Inventory::StockHelper

   def build_stock_form(stock_item,action,caption,is_edit = nil,is_create_retry = nil)

      session[:stock_item_form]= Hash.new

      #generate javascript for the on_complete ajax event for each combo
      search_combos_js = gen_combos_clear_js_for_combos(["stock_item_party_type_name", "stock_item_party_name", "stock_item_parties_role_name"])
      #Observers for search combos

      party_type_name_observer  = {:updated_field_id => "party_name_cell",
             :remote_method => 'stock_item_party_type_name_combo_changed',
             :on_completed_js =>search_combos_js["stock_item_party_type_name"]}

      session[:stock_item_form][:party_type_name_observer] = party_type_name_observer

      party_name_observer  = {:updated_field_id => "parties_role_name_cell",
             :remote_method => 'stock_item_party_name_combo_changed',
             :on_completed_js => search_combos_js["stock_item_party_name"]}

      session[:stock_item_form][:party_name_observer] = party_name_observer
      
      stock_type_codes = StockType.find_by_sql("select * from stock_types").map{|g|[g.stock_type_code]}
      stock_type_codes.unshift("<empty>")
      location_codes = Location.find_by_sql("select * from locations").map{|g|[g.location_code]}
      location_codes.unshift("<empty>")
      #party_codes = Party.find_by_sql("select * from parties").map{|g|[g.party_name]}
      #party_codes.unshift("<empty>")
      reference_numbers = InventoryReceipt.find_by_sql("select * from inventory_receipts").map{|g|[g.reference_number]}
      reference_numbers.unshift("<empty>")
      transaction_business_names = TransactionBusinessName.find_by_sql("select distinct transaction_business_name_code from transaction_business_names").map{|g|[g.transaction_business_name_code]}
      transaction_business_names.unshift("<empty>")
      
      status_codes = Status.find_by_sql("select distinct status_code from statuses").map{|g|[g.status_code]}
      status_codes.unshift("<empty>")

      party_type_names = nil
      party_names = nil
      role_names = nil

      party_type_names = PartiesRole.find_by_sql("select distinct party_type_name from parties").map{|g|[g.party_type_name]}
      party_type_names.unshift("<empty>")

      if stock_item == nil || is_create_retry
         party_names = ["Select a value from party_type_name"]
         role_names = ["Select a value from party_name"]
      else
         party_names = PartiesRole.find_by_sql("select distinct party_name from parties").map{|g|[g.party_name]}
         party_names.unshift("<empty>")
         role_names = PartiesRole.find_by_sql("select distinct role_name from parties_roles").map{|g|[g.role_name]}
         role_names.unshift("<empty>")
         parties_role = PartiesRole.find_by_id_and_role_name(stock_item.parties_role_id, stock_item.parties_role_name)
         if parties_role
           stock_item.party_type_name = parties_role.party_type_name
           stock_item.party_name = parties_role.party_name
         end
      end
      
      field_configs = Array.new

      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'inventory', :settings=>{:static_value=>'INVENTORY_TRANSACTION', :is_separator=>true}}
      receipt_text_field_string = text_field(:stock_item, :inventory_receipt_reference_number)
      receipt_url = "http://" + request.host_with_port + "/inventory/grouped_assets/lookup_receipt"
      receipt_link = link_to("lookup receipt", receipt_url, {:class => "action_link"})
      field_config = {:settings=>{
                    :link_text=>'lookup receipt',
                    :host_and_port =>request.host_with_port.to_s,
                    :controller => 'inventory/stock',
                    :target_action=>'lookup_receipt'
              }}
      link_popup_window_field = ApplicationHelper::LinkPopUpWindow_field.new(nil,nil, 'none','none','none',field_config,true,nil,self)

      #receipt_label_value = receipt_text_field_string + "&nbsp;" + receipt_link
      receipt_label_value = receipt_text_field_string + "&nbsp;" + link_popup_window_field.build_control
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'inventory_receipt',
                                               :settings=>{
                                                  :static_value => receipt_label_value,
                                                  :is_separator => false,
                                                  :show_label=>true,
                                                  :css_class=>'unbordered_label_field'
                                               }}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'reference_number'}
      #field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'inventory_receipt',:settings=>{:list=>reference_numbers}}
      #field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'', :settings=>{:link_text=>'create_receipt',:target_action=>'new_receipt', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'transaction_business_name',:settings=>{:list=>transaction_business_names}}

      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'stock', :settings=>{:static_value=>'STOCK_ITEM', :is_separator=>true}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'stock_type',:settings=>{:list=>stock_type_codes}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'location_code',:settings=>{:list=>location_codes}}
      #field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_name',:settings=>{:list=>party_codes}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_type_name', :settings=>{:list=>party_type_names}, :observer=>party_type_name_observer}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_name', :settings=>{:list=>party_names}, :observer=>party_name_observer}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'parties_role_name', :settings=>{:list=>role_names}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'inventory_reference'}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'quantity', :settings=>{:static_value=>1, :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'status_code',:settings=>{:list=>status_codes}}

     field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'transaction_type', :settings =>{:static_value =>'create_stock', :show_label=>true}}

      build_form(stock_item,field_configs,action,'stock_item',caption,is_edit)
   end
   
   def build_find_stock_form(stock_item,action,caption,is_edit = nil,is_create_retry = nil)
      stock_type_codes = StockType.find_by_sql("select * from stock_types").map{|g|[g.stock_type_code]}
      stock_type_codes.unshift("<empty>")
      location_codes = Location.find_by_sql("select * from locations").map{|g|[g.location_code]}
      location_codes.unshift("<empty>")
      party_codes = Party.find_by_sql("select * from parties").map{|g|[g.party_name]}
      party_codes.unshift("<empty>")
      
      farm_codes = Farm.find_by_sql("select distinct farm_code from farms").map{|g|[g.farm_code]}
      farm_codes.unshift("<empty>")
      
      reference_numbers = InventoryTransaction.find_by_sql("select distinct reference_number from inventory_transactions").map{|g|[g.reference_number]}
      reference_numbers.unshift("<empty>")
      
      transaction_business_names = TransactionBusinessName.find_by_sql("select * from transaction_business_names").map{|g|[g.transaction_business_name_code]}
      transaction_business_names.unshift("<empty>")
      
      transaction_type_codes = TransactionType.find_by_sql("select distinct transaction_type_code from transaction_types").map{|g|[g.transaction_type_code]}
      transaction_type_codes.unshift("<empty>")
      
      status_codes = Status.find_by_sql("select distinct status_code from statuses").map{|g|[g.status_code]}
      status_codes.unshift("<empty>")
      
      field_configs = Array.new
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'stock_type',:settings=>{:list=>stock_type_codes}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'location',:settings=>{:list=>location_codes}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_name',:settings=>{:list=>party_codes}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'inventory_reference'}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'farm_code', :settings=>{:list=>farm_codes}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'truck_code'}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'reference_number',:settings=>{:list=>reference_numbers}}
      #field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'', :settings=>{:link_text=>'create_receipt',:target_action=>'new_receipt', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'transaction_business_name',:settings=>{:list=>transaction_business_names}}
      field_configs[field_configs.length()] = {:field_type =>'DropDownField', :field_name => 'transaction_type_code', :settings =>{:list=>transaction_type_codes}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'status_code',:settings=>{:list=>status_codes}}
      
      build_form(stock_item,field_configs,action,'stock',caption,is_edit)
   end
   
   #============================================
   # Inventory_Receipt helper Methods
   #============================================
   def build_inventory_receipt_form(inventory_receipt,action,caption, is_edit=nil,is_create_retry=nil)
      #--------------------------------------------------------------------------------------------------
      #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
      #	in a composite foreign key
      #--------------------------------------------------------------------------------------------------
	  session[:inventory_receipt_form]= Hash.new
	  
	  #generate javascript for the on_complete ajax event for each combo
	  search_combos_js_for_pack_material = gen_combos_clear_js_for_combos(["inventory_receipt_pack_material_type_code", "inventory_receipt_pack_material_subtype_code","inventory_receipt_pack_material_product_code"])
	  #Observers for search combos
	  
	  on_complete_js_party_type_name = "\n img = document.getElementById('img_inventory_receipt_party_type_name');"
	  on_complete_js_party_type_name += "\n if(img != null) img.style.display = 'none';"
	  
	  party_type_name_observer  = {:updated_field_id => "party_name_cell",
					 :remote_method => 'inventory_receipt_party_type_name_search_combo_changed',
					 :on_completed_js => on_complete_js_party_type_name}#search_combos_js["parties_role_party_type_name"]}

	  session[:inventory_receipt_form][:party_type_name_observer] = party_type_name_observer
	  
	  on_complete_js_party_name = "\n img = document.getElementById('img_inventory_receipt_party_name');"
	  on_complete_js_party_name += "\n if(img != null) img.style.display = 'none';"

	  party_name_observer  = {:updated_field_id => "parties_role_name_cell",
					 :remote_method => 'inventory_receipt_party_name_search_combo_changed',
					 :on_completed_js => on_complete_js_party_name}

	  session[:inventory_receipt_form][:party_name_observer] = party_name_observer
	  
	  pack_material_type_code_observer = {:updated_field_id=>"pack_material_subtype_code_cell",
	                                      :remote_method=>'inventory_receipt_pack_material_type_code_changed',
	                                      :on_completed_js=>search_combos_js_for_pack_material["inventory_receipt_pack_material_type_code"]}
	                                     
	  session[:inventory_receipt_form][:pack_material_type_code_observer] = pack_material_type_code_observer
	  
	  pack_material_subtype_code_observer = {:updated_field_id=>"pack_material_product_code_cell",
	                                      :remote_method=>'inventory_receipt_pack_material_subtype_code_changed',
	                                      :on_completed_js=>search_combos_js_for_pack_material["inventory_receipt_pack_material_subtype_code"]}
	                                     
	  session[:inventory_receipt_form][:pack_material_subtype_code_observer] = pack_material_subtype_code_observer
	  
	  party_type_names = nil 
	  party_names = nil 
	  role_names = nil 
	  
	  pack_material_type_codes = nil
	  pack_material_subtype_codes = nil
	  pack_material_product_codes = nil
	  
	  farm_codes = nil
	  inventory_receipt_type_codes = nil
	  
	  pack_material_type_codes = PackMaterialType.find_by_sql("select distinct pack_material_type_code from pack_material_types").map{|g|[g.pack_material_type_code]}
	  pack_material_type_codes.unshift("<empty>")
	  
	  party_type_names = Party.find_by_sql("select distinct party_type_name from parties").map{|g|[g.party_type_name]}
	  party_type_names.unshift("<empty>")
	  
	  farm_codes = Farm.find_by_sql("select distinct farm_code from farms").map{|g|[g.farm_code]}
	  farm_codes.unshift("<empty>")
	  
	  inventory_receipt_type_codes = InventoryReceiptType.find_by_sql("select distinct inventory_receipt_type_code from inventory_receipt_types").map{|g|[g.inventory_receipt_type_code]}
	  inventory_receipt_type_codes.unshift("<empty>")
	  
	  if inventory_receipt == nil || is_create_retry
	     party_names = ["Select a value from party_type_name"]
		 role_names = ["Select a value from party_name"]
		 pack_material_subtype_codes = ["Select a value from pack_material_type_code"]
		 pack_material_product_codes = ["Select a value from pack_material_subtype_code"]
	  else
	     party_names = Party.find_by_sql("select distinct party_name from parties").map{|g|[g.party_name]}
	     party_names.unshift("<empty>")
	     role_names = PartiesRole.find_by_sql("select distinct role_name from parties_roles").map{|g|[g.role_name]}
	     role_names.unshift("<empty>")
	  end
	  
	  field_configs = Array.new
	  
	  field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'receipt_date_time', :settings => {:date_textfield_id=>'receipt_date_time'}}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_type_name', :settings=>{:list=>party_type_names}, :observer=>party_type_name_observer}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_name', :settings=>{:list=>party_names}, :observer=>party_name_observer}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'parties_role_name', :settings=>{:list=>role_names}}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'farm_code', :settings=>{:list=>farm_codes}}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'quantity_received'}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'pack_material_type_code', :settings=>{:list=>pack_material_type_codes}, :observer=>pack_material_type_code_observer}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'pack_material_subtype_code', :settings=>{:list=>pack_material_subtype_codes}, :observer=>pack_material_subtype_code_observer}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'pack_material_product_code', :settings=>{:list=>pack_material_product_codes}}
	  field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'comments'}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'quantity_on_farms'}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'truck_code'}
	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'inventory_receipt_type_code', :settings=>{:list=>inventory_receipt_type_codes}}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'quantity_damaged'}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'reference_id'}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'reference_number'}
	  
	  build_form(inventory_receipt,field_configs,action,'inventory_receipt',caption,is_edit)
	  
   end
   
   def build_stock_grid(recordset)
      column_configs = Array.new
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'stock_type_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'location_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'party_name'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'inventory_reference'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'farm_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'truck_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'reference_number'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_business_name_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_type_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'status_code'}
      
      column_configs[column_configs.length()] = {:field_type=>'action', :field_name=>'manage',
                                                  :settings=>{:link_text=>'manage',
                                                             :target_action=>'manage_stock',
                                                             :id_column=>'id'}}
     
     return get_data_grid(recordset,column_configs,nil,true)
   end
   
   def build_manage_stock_item_form(stock_item,action,caption,is_edit = nil,is_create_retry=nil)

      session[:stock_item_form]= Hash.new

      #generate javascript for the on_complete ajax event for each combo
      search_combos_js = gen_combos_clear_js_for_combos(["stock_item_party_type_name", "stock_item_party_name", "stock_item_parties_role_name"])
      #Observers for search combos

      party_type_name_observer  = {:updated_field_id => "party_name_cell",
             :remote_method => 'stock_item_party_type_name_combo_changed',
             :on_completed_js =>search_combos_js["stock_item_party_type_name"]}

      session[:stock_item_form][:party_type_name_observer] = party_type_name_observer

      party_name_observer  = {:updated_field_id => "parties_role_name_cell",
             :remote_method => 'stock_item_party_name_combo_changed',
             :on_completed_js => search_combos_js["stock_item_party_name"]}

      session[:stock_item_form][:party_name_observer] = party_name_observer
      
      
      stock_type_codes = StockType.find_by_sql("select distinct stock_type_code from stock_types").map{|g|[g.stock_type_code]}
      stock_type_codes.unshift("<empty>")
      
      location_codes = Location.find_by_sql("select distinct location_code from locations").map{|g|[g.location_code]}
      location_codes.unshift("<empty>")
      
      #party_codes = Party.find_by_sql("select distinct party_name from parties").map{|g|[g.party_name]}
      #party_codes.unshift("<empty>")
      
      farm_codes = Farm.find_by_sql("select distinct farm_code from farms").map{|g|[g.farm_code]}
      farm_codes.unshift("<empty>")
      
      reference_numbers = InventoryTransaction.find_by_sql("select distinct reference_number from inventory_transactions").map{|g|[g.reference_number]}
      reference_numbers.unshift("<empty>")
      
      transaction_business_names = TransactionBusinessName.find_by_sql("select distinct transaction_business_name_code from transaction_business_names").map{|g|[g.transaction_business_name_code]}
      transaction_business_names.unshift("<empty>")
      
      #transaction_type_codes = TransactionType.find_by_sql("select distinct transaction_type_code from transaction_types").map{|g|[g.transaction_type_code]}
      #transaction_type_codes.unshift("<empty>")
      
      status_codes = Status.find_by_sql("select distinct status_code from statuses").map{|g|[g.status_code]}
      status_codes.unshift("<empty>")

      party_type_names = nil
      party_names = nil
      role_names = nil

      party_type_names = PartiesRole.find_by_sql("select distinct party_type_name from parties").map{|g|[g.party_type_name]}
      party_type_names.unshift("<empty>")

      if stock_item == nil || is_create_retry
         party_names = ["Select a value from party_type_name"]
         role_names = ["Select a value from party_name"]
      else
         party_names = PartiesRole.find_by_sql("select distinct party_name from parties").map{|g|[g.party_name]}
         party_names.unshift("<empty>")
         role_names = PartiesRole.find_by_sql("select distinct role_name from parties_roles").map{|g|[g.role_name]}
         role_names.unshift("<empty>")
         parties_role = PartiesRole.find_by_id_and_role_name(stock_item.parties_role_id, stock_item.parties_role_name)
         if parties_role
           stock_item.party_type_name = parties_role.party_type_name
           stock_item.party_name = parties_role.party_name
         end
      end
      
      stock_item.reference_number = stock_item.inventory_transaction.reference_number
      puts "REF NUMBER == : " + stock_item.reference_number
      stock_item.transaction_business_name_code = stock_item.inventory_transaction.transaction_business_name_code
      stock_item.transaction_type_code = stock_item.inventory_transaction.transaction_type_code
      #stock_item.inventory_receipt_reference_number = stock_item.inventory_transaction.inventory_receipt.reference_number
      stock_item.inventory_receipt_reference_number = stock_item.inventory_transaction.reference_number
      #stock_item.farm_code = stock_item.inventory_transaction.inventory_receipt.farm_code
      #stock_item.truck_code = stock_item.inventory_transaction.inventory_receipt.truck_code
      
      field_configs = Array.new

      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'inventory', :settings=>{:static_value=>'INVENTORY_TRANSACTION', :is_separator=>true}}
      receipt_text_field_string = text_field(:stock_item, :inventory_receipt_reference_number)
      receipt_url = "http://" + request.host_with_port + "/inventory/grouped_assets/lookup_receipt"
      receipt_link = link_to("lookup receipt", receipt_url, {:class => "action_link"})
      field_config = {:settings=>{
                    :link_text=>'lookup receipt',
                    :host_and_port =>request.host_with_port.to_s,
                    :controller => 'inventory/stock',
                    :target_action=>'lookup_receipt'
              }}
      link_popup_window_field = ApplicationHelper::LinkPopUpWindow_field.new(nil,nil, 'none','none','none',field_config,true,nil,self)

      #receipt_label_value = receipt_text_field_string + "&nbsp;" + receipt_link
      receipt_label_value = receipt_text_field_string + "&nbsp;" + link_popup_window_field.build_control
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'inventory_receipt',
                                               :settings=>{
                                                  :static_value => receipt_label_value,
                                                  :is_separator => false,
                                                  :show_label=>true,
                                                  :css_class=>'unbordered_label_field'
                                               }}
      #field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'farm_code', :settings=>{:list=>farm_codes}}
      #field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'truck_code'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'reference_number'}
      #field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'', :settings=>{:link_text=>'create_receipt',:target_action=>'new_receipt', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'transaction_business_name_code',:settings=>{:list=>transaction_business_names}}

      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'stock', :settings=>{:static_value=>'STOCK_ITEM', :is_separator=>true}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'stock_type_code',:settings=>{:list=>stock_type_codes}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'location_code',:settings=>{:list=>location_codes}}
      #field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_name',:settings=>{:list=>party_codes}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_type_name', :settings=>{:list=>party_type_names}, :observer=>party_type_name_observer}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_name', :settings=>{:list=>party_names}, :observer=>party_name_observer}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'parties_role_name', :settings=>{:list=>role_names}}
      #field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'inventory_reference'}
     field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'inventory_reference', :settings=>{:link_text=>stock_item.inventory_reference.to_s,:target_action=>'view_object_details', :id_column=>'inventory_reference', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      #field_configs[field_configs.length()] = {:field_type =>'DropDownField', :field_name => 'transaction_type_code', :settings =>{:list=>transaction_type_codes}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'status_code',:settings=>{:list=>status_codes}}
      
      field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'', :settings=>{:link_text=>'view_transaction_history',:target_action=>'view_transaction_history', :id_column=>'id', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'', :settings=>{:link_text=>'view_status_history',:target_action=>'view_status_history', :id_column=>'id', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'', :settings=>{:link_text=>'view_asset',:target_action=>'view_asset', :id_column=>'inventory_reference', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'', :settings=>{:link_text=>'apply_to_list',:target_action=>'apply_to_list', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'', :settings=>{:link_text=>'selected_items',:target_action=>'selected_items', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      field_configs[field_configs.length()] = {:field_type=>'link_window_field', :field_name=>'', :settings=>{:link_text=>'remove_stock',:target_action=>'remove_stock', :id_column=>'id', :host_and_port =>request.host_with_port.to_s, :controller =>request.path_parameters['controller'].to_s}}
      link_url = "http://" + request.host_with_port + "/inventory/stock/remove_stock/" + stock_item.id.to_s
      link = link_to("remove_stock", link_url, {:class => "action_link"})
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'remove_stock', :settings=>{:static_value=>link, :show_lable=>true, :non_db_field=>true, :css_class=>'unbordered_label_field'}}

      build_form(stock_item,field_configs,action,'stock_item',caption,is_edit)
      
   end
   
   def build_stock_inventory_transaction_history_grid(recordset)
      column_configs = Array.new
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'location_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'location_from'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'location_from'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_quantity_plus'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_quantity_minus'}
      #column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'truck_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'reference_number'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_business_name'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_type_code'}
      #column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'current_status'}
     
     return get_data_grid(recordset,column_configs)
   end
   
   def build_stock_item_statuses_history_grid(recordset)
     column_configs = Array.new
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'created_on'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'hold_date_from'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'hold_date_to'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'quarantine_date_from'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'quarantine_date_to'}
      #column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'truck_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'reason'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'comment'}
      #column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_type_code'}
      #column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'current_status'}
     
     return get_data_grid(recordset,column_configs)
   end
   
   def build_view_asset_item_form(asset_item,action,caption)
      field_configs = Array.new
      asset_item.attributes.each do |key,val|
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>key.to_s}
      end
      field_configs.sort!{|x,y| x[:field_name]<=>y[:field_name]}
      build_form(asset_item,field_configs,action,'asset_item',caption)
   end
   
   def build_apply_to_list_grid(recordset,is_multi_select = nil)
      column_configs = Array.new
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'inventory_reference'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'stock_type_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'current_location'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'party_name'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'farm_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'truck_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'reference_number'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_business_name_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_type_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'status_code'}
      column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'id'}
      
      @multi_select = "selected_stock_items" if is_multi_select
      
      return get_data_grid(recordset,column_configs,nil,true)
   end
   
   def build_selected_items_grid(recordset)
      column_configs = Array.new
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'stock_type_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'location_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'party_name'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'inventory_reference'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'farm_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'truck_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'reference_number'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_business_name_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'transaction_type_code'}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'status_code'}
     
     return get_data_grid(recordset,column_configs,nil,true)
   end

   def build_lookup_inventory_issue_form(inventory_issue,action,caption,is_edit = nil,is_create_retry = nil)
      field_configs = Array.new
      receipt_text_field_string = text_field(:inventory_issue, :reference_number)
      #receipt_url = "http://" + request.host_with_port + "/inventory/grouped_assets/lookup_receipt"
      #receipt_link = link_to("lookup receipt", receipt_url, {:class => "action_link"})
      field_config = {:settings=>{
                    :link_text=>'lookup issue',
                    :host_and_port =>request.host_with_port.to_s,
                    :controller => 'inventory/grouped_assets',
                    :target_action=>'lookup_inventory_issue'
              }}
      link_popup_window_field = ApplicationHelper::LinkPopUpWindow_field.new(nil,nil, 'none','none','none',field_config,true,nil,self)

      #receipt_label_value = receipt_text_field_string + "&nbsp;" + receipt_link
      receipt_label_value = receipt_text_field_string + "&nbsp;" + link_popup_window_field.build_control
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'inventory_issue',
                                               :settings=>{
                                                  :static_value => receipt_label_value,
                                                  :is_separator => false,
                                                  :show_label=>true,
                                                  :css_class=>'unbordered_label_field'
                                               }}
      build_form(inventory_issue,field_configs,action,'inventory_issue',caption,is_edit)
   end

end