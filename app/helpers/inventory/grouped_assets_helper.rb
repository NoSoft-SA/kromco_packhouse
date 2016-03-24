module Inventory::GroupedAssetsHelper
#===================================
#===================================
#== Start of the Bin control app  ==
#===================================
#===================================
  def build_asset_item_form(asset_item_rec,action,caption,is_edit = nil,is_create_retry = nil)
    session[:asset_item_form]= Hash.new
    search_combos_js = gen_combos_clear_js_for_combos(["asset_item_pack_material_type_code","asset_item_pack_material_sub_type_code", "asset_item_ownership" , "asset_item_pack_material_product_code"])
    more_search_combos_js = gen_combos_clear_js_for_combos(["asset_item_owner_type", "asset_item_owner"])
	  #Observers for search combos

	  pack_material_type_code_observer  = {:updated_field_id => "pack_material_sub_type_code_cell",
					 :remote_method => 'asset_item_pack_material_type_code_combo_changed',
					 :on_completed_js =>search_combos_js["asset_item_pack_material_type_code"]}

	  session[:asset_item_form][:pack_material_type_code_observer] = pack_material_type_code_observer

    pack_material_sub_type_code_observer = {:updated_field_id=>"ownership_cell",
	                                      :remote_method=>'asset_item_pack_material_subtype_code_changed',
	                                      :on_completed_js=>search_combos_js["asset_item_pack_material_sub_type_code"]}

	  session[:asset_item_form][:pack_material_sub_type_code_observer] = pack_material_sub_type_code_observer

    ownership_observer = {:updated_field_id=>"pack_material_product_code_cell",
	                                      :remote_method=>'asset_item_ownership_changed',
	                                      :on_completed_js=>search_combos_js["asset_item_ownership"]}

	  session[:asset_item_form][:ownership_observer] = ownership_observer

    owner_type_observer = {:updated_field_id=>"owner_cell",
	                                      :remote_method=>'asset_item_owner_type_changed',
	                                      :on_completed_js=>more_search_combos_js["asset_item_owner_type"]}

	  session[:asset_item_form][:owner_type_observer] = owner_type_observer


    pack_material_type_codes = PackMaterialType.find(:all,:select => "distinct(pack_material_type_code)").map{|g|[g.pack_material_type_code]}
    party_type_codes = Party.find(:all,:select => "distinct(party_type_name)").map{|g|[g.party_type_name]}

    pack_material_sub_type_codes = ["Select a value from pack material type code"]
    ownerships = ["Select a value from pack material sub type code"]
    pack_material_product_codes = ["Select a value from pack ownership"]
    owners = ["Select a value from pack owner type"]

    field_configs = Array.new
    if(!is_edit)
      field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'pack_material_type_code',
                                         :observer=>pack_material_type_code_observer,
                                         :settings =>{:list=>pack_material_type_codes}}
      
      field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'pack_material_sub_type_code',
                                               :observer=>pack_material_sub_type_code_observer,
                                               :settings =>{:list=>pack_material_sub_type_codes}}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'ownership',
                                               :observer=>ownership_observer,
                                               :settings =>{:list=>ownerships}}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'pack_material_product_code',
                                               :settings =>{:list=>pack_material_product_codes}}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'owner_type',
                                               :observer=> owner_type_observer,
                                               :settings =>{:list=>party_type_codes}}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'owner',
                                               :settings =>{:list=>owners}}
    else
      asset_loccation_qty = AssetLocation.find_by_sql("select sum(location_quantity) as location_quantity_sum from asset_locations where asset_item_id = #{asset_item_rec.id}").map{|g| g.location_quantity_sum}[0]
      if(!asset_loccation_qty || asset_loccation_qty == 0)
        field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'pack_material_type_code',
                                         :observer=>pack_material_type_code_observer,
                                         :settings =>{:list=>pack_material_type_codes}}
        
        field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'pack_material_sub_type_code',
                                                 :settings =>{:list=>[asset_item_rec.pack_material_sub_type_code.to_s],:no_empty=>true}}

#        field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'ownership',
#                                                 :settings =>{:list=>[asset_item_rec.ownership.to_s],:no_empty=>true}}

        field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'pack_material_product_code',
                                                 :settings =>{:list=>[asset_item_rec.pack_material_product_code.to_s],:no_empty=>true}}

        field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'owner_type',
                                                 :settings =>{:list=>[asset_item_rec.owner_type.to_s],:no_empty=>true}}

        field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'owner',
                                                 :settings =>{:list=>[asset_item_rec.owner.to_s],:no_empty=>true}}

      else
        field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'pack_material_type_code',
                                         :settings =>{:static_value=>asset_item_rec.pack_material_type_code.to_s,:show_label=>true}}

        field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'pack_material_sub_type_code',
                                               :settings =>{:static_value=>asset_item_rec.pack_material_sub_type_code.to_s,:show_label=>true}}

#        field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'ownership',
#                                                 :settings =>{:static_value=>asset_item_rec.ownership.to_s,:show_label=>true}}

        field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'pack_material_product_code',
                                                 :settings =>{:static_value=>asset_item_rec.pack_material_product_code.to_s,:show_label=>true}}

        field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'owner_type',
                                                 :settings =>{:static_value=>asset_item_rec.owner_type.to_s,:show_label=>true}}

        field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'owner',
                                                 :settings =>{:static_value=>asset_item_rec.owner.to_s,:show_label=>true}}
      end

#      asset_locs = AssetLocation.find_by_sql("select count(*) as count from asset_locations where asset_item_id = #{asset_item_rec.id}")
      asset_locs = AssetLocation.find_by_sql("select sum(location_quantity) as count from asset_locations where asset_item_id = #{asset_item_rec.id}")#[2011]
      field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'total asset count',
                                               :settings=>{:static_value=>asset_locs[0].count.to_s,:show_label=>true}}

      id_value = asset_item_rec.id
      
      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                             :field_name => '',
                                             :settings => {
                                                     :target_action => 'view_latest_asset_transaction',
                                                     :link_text => "view latest asset transaction",
                                                     :id_value => id_value
                                             }}

      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                             :field_name => '',
                                             :settings => {
                                                     :target_action => 'search_asset_item_transaction_history',
                                                     :link_text => "search transaction history",
                                                     :id_value => id_value
                                             }}

#      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
#                                             :field_name => '',
#                                             :settings => {
#                                                     :target_action => 'create_asset_location',
#                                                     :link_text => "add asset location",
#                                                     :id_value => id_value
#                                             }}
    end

    if(is_edit)

      field_configs[field_configs.length()] = {:field_type => 'Screen',
						                  :field_name => "asset_locations_grid_form",
						                  :settings =>{:target_action => "render_asset_locations_grid",
                                          :width=>990,:height=>330,:no_scroll => true,
						                              :id_value =>asset_item_rec.id}}
      set_submit_button_align('left')      
      set_form_layout "3", nil, 0, 9
    else
      set_form_layout "1", nil, 0, 8
    end

    build_form(nil,field_configs,action,'asset_item',caption,is_edit)#asset_item
  end

  def build_asset_location_form(location,action,caption)
    location_codes = Location.find(:all,:select => "distinct(location_code),id").map{|g|[g.location_code,g.id]}
    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'location_code',
                                             :settings =>{:list=>location_codes}}

    build_form(location,field_configs,action,'location',caption)
  end

  def build_asset_location_grid(locations,can_edit,can_delete)
    column_configs = Array.new
    #	----------------------
    #	define action columns
    #	----------------------
    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'add_assets', :col_width=> 42,
      :settings =>
             {:link_text => 'add',
              :target_action => 'add_assets',
              :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'remove_assets', :col_width=> 53,
      :settings =>
             {:link_text => 'remove',
              :target_action => 'remove_assets',
              :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'move_assets', :col_width=> 45,
      :settings =>
             {:link_text => 'move',
              :target_action => 'move_asset_quantity',
              :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'delete_asset_location', :col_width=> 39,
      :settings =>
             {:link_text => 'delete',
              :target_action => 'delete_asset_location',
              :id_column => 'asset_location_id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'search_transaction_history', :col_width=> 126,
      :settings =>
             {:link_text => 'search transaction history',
              :target_action => 'view_asset_location_transaction_history',
              :id_column => 'asset_location_id'}}

    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'location_type_code', :col_width=> 123}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'location_code', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'assets_in_location', :col_width=> 53}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'parent_location_code', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'units_in_location', :col_width=> 50}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'location_maximum_units', :col_width=> 56}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'location_status', :col_width=> 167}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'current_job_reference_id', :col_width=> 102}

#    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view_stock',
#      :settings =>
#             {:link_text => 'view_stock',
#              :target_action => 'view_stock',
#              :id_column => 'id'}}

    grid_command =    {:field_type=>'link_window_field',:field_name =>'new_voyage_port',
                              :settings =>
                             {:id_value      =>@asset_class_id,
                              :host_and_port =>request.host_with_port.to_s,
                              :controller    => request.path_parameters['controller'].to_s,
                              :target_action =>'create_asset_location',
                              :link_text => "add asset location"}}

    set_grid_min_height(145)
    set_grid_min_width(730)
    return get_data_grid(locations,column_configs,nil,nil,grid_command)
  end

  def build_list_asset_classes_grid(data_set, can_edit, can_delete)
    column_configs = Array.new

#    data_set[0].keys.each do |key|
#      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => key}
#    end

    if (can_edit)
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit', :col_width=> 35,
                                                 :settings =>
                                                         {:image => 'edit',
                                                          :target_action => 'edit_asset_class',
                                                          :id_column => 'id'}}
    end

    if (can_delete)
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete', :col_width=> 35,
                                                 :settings =>
                                                         {:image => 'delete',
                                                          :target_action => 'delete_asset_class',
                                                          :id_column => 'id'}}
    end

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_reference', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'depreciation_percentage', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'acquisition_price', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'parties_role_name', :col_width=> 100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'quantity', :col_width=> 51}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'party_name', :col_width=> 155}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'acquisition_date', :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'current_status', :col_width=> 90}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'asset_number', :col_width=> 110}

    return get_data_grid(data_set, column_configs, nil, true)
  end

  def build_list_transaction_histories_grid(data_set, can_edit, can_delete)
    column_configs = Array.new

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'print_report', :col_width=> 42,
                                               :settings =>
                                                   {:link_text => 'print_report',
                                                    :target_action => '',
                                                    :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_quantity_minus', :col_width=> 46}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'reference_number', :col_width=> 53}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'updated_at', :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'is_stock_asset_move', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_from', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'comments', :col_width=> 100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_by', :col_width=> 57}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'affected_by_function', :col_width=> 170}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'updated_by', :col_width=> 98}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'truck_license_number', :col_width=> 85}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_to', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'affected_by_env', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_type_code', :col_width=> 144}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_quantity_plus', :col_width=> 46}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'asset_number', :col_width=> 110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_date_time', :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_business_name_code', :col_width=> 255}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'affected_by_program', :col_width=> 213}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_at', :col_width=> 134}

    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Inventory::GroupedAssetsGridPlugin.new(self,request), true)
  end

  def build_list_asset_location_transaction_histories_grid(data_set, can_edit, can_delete)

    column_configs = Array.new

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_quantity_minus', :col_width=> 47}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on', :col_width=> 135}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_from', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_quantity', :col_width=> 47}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_to', :col_width=> 127}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_type', :col_width=> 157}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_quantity_plus', :col_width=> 47}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'asset_number', :col_width=> 119}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_business_name_code', :col_width=> 225}

    return get_data_grid(data_set, column_configs, nil, true)
  end

  def build_add_remove_assets_form(asset_item,action,caption,is_add)
#    farm_codes = Farm.find(:all,:select => "distinct(farm_code),id").map{|g|[g.farm_code]}#,g.id]}
    transaction_business_name_codes = TransactionBusinessName.find(:all,:select => "distinct(transaction_business_name_code),id").map{|g|[g.transaction_business_name_code]}#,g.id]}

    field_configs = Array.new
#    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'farm_code',
#                                             :settings =>{:list=>farm_codes}}

    if(is_add)
      qty_field_name = 'quantity_received'
    else
      qty_field_name = 'quantity_removed'
    end
    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => qty_field_name}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'bus_transaction_type',
                                             :settings =>{:list=>transaction_business_name_codes}}

#    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'quantity_on_farms'}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'truck_code'}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'reference_number'}

    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'receipt_date_time', :settings => {:date_textfield_id=>'receipt_date_time'}}

    field_configs[field_configs.length()] = {:field_type => 'TextArea', :field_name => 'comments'}

    build_form(asset_item,field_configs,action,'asset_item',caption)
  end

  def build_move_assets_form(asset_item,action,caption)
    location_codes = Location.find(:all,:select => "distinct(location_code),id").map{|g|[g.location_code]}
    transaction_business_name_codes = TransactionBusinessName.find(:all,:select => "distinct(transaction_business_name_code),id").map{|g|[g.transaction_business_name_code]}#,g.id]}

    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'to_location',
                                             :settings =>{:list=>location_codes}}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'qty_to_move'}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'bus_transaction_type',
                                             :settings =>{:list=>transaction_business_name_codes}}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'reference_number'}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'truck_code'}

    field_configs[field_configs.length()] = {:field_type => 'TextArea', :field_name => 'comments'}

    build_form(asset_item,field_configs,action,'asset_item',caption)
  end

  def build_view_stock_grid(data_set)
    puts "Data set = " + data_set.class.name
    column_configs = Array.new
    data_set[0].attributes.keys.each do |key|
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => key}
    end
    return get_data_grid(data_set, column_configs, nil, true)
  end


  def build_stock_transaction_histories_search_form(inventory_transaction,action,caption)
    field_configs = Array.new
    field_configs << {:field_type => 'TextField', :field_name => 'inventory_reference',
                      :settings=>{:label_caption=> 'stock item'}}
    field_configs << {:field_type =>'PopupDateRangeSelector',
              :field_name =>'transaction_date_time'}
    field_configs << {:field_type => 'TextField', :field_name => 'stock_type_code'}
    field_configs << {:field_type => 'TextField', :field_name => 'pack_material_product_code'}
    field_configs << {:field_type => 'TextField', :field_name => 'location_code'}
    field_configs << {:field_type => 'TextField', :field_name => 'transaction_business_name_code'}
    field_configs << {:field_type => 'TextField', :field_name => 'transaction_type_code'}
    build_form(inventory_transaction,field_configs,action,'inventory_transaction',caption)
  end

  def build_list_stock_transaction_histories_grid(data_set)
    column_configs = Array.new

     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_to', :col_width=> 142}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'reference_number', :col_width=> 53}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_business_name_code', :col_width=> 255}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_date_time', :col_width=> 134}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_quantity_minus', :col_width=> 46}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_quantity_plus', :col_width=> 46}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_type_code', :col_width=> 144}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_from', :col_width=> 142}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'stock_type_code', :col_width=> 144}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_reference', :col_width=> 55}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_material_product_code', :col_width=> 110}

    return get_data_grid(data_set, column_configs, nil, true)
  end

  def build_stock_locations_histories_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_reference', :col_width=> 55}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on', :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'units_in_location_before', :col_width=> 55}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'units_in_location_after', :col_width=> 55}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'stock_type', :col_width=> 144}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => ''}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => ''}

    return get_data_grid(data_set, column_configs, nil, true)
  end
end