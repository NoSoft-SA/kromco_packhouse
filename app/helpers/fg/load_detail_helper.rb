module Fg::LoadDetailHelper

  def build_edit_pallet_form(pallet, action, caption, is_edit = nil, is_create_retry = nil)

           field_configs = Array.new
           field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'pallet_number'}
           field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks1',:settings=>{:label_caption=>Globals.get_column_captions['remarks1']} }
           field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks2',:settings=>{:label_caption=>Globals.get_column_captions['remarks2']}}
           field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks3',:settings=>{:label_caption=>Globals.get_column_captions['remarks3']}}
           field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks4',:settings=>{:label_caption=>Globals.get_column_captions['remarks4']}}
           field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks5',:settings=>{:label_caption=>Globals.get_column_captions['remarks5']}}

        build_form(pallet, field_configs, action, 'pallet', caption, is_edit)

      end
  def build_load_detail_form(load_detail, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:load_detail_form]= Hash.new
    uom_codes = Uom.find_by_sql('select distinct uom_code from uoms').map { |g| [g.uom_code] }
    #generate javascript for the on_complete ajax event for each combo for fk table: orders
    combos_js_for_orders = gen_combos_clear_js_for_combos(["load_detail_order_number", "load_detail_customer_party_role_id"])
    #Observers for combos representing the key fields of fkey table: order_id
    fg_product_codes = FgProduct.find_by_sql('select distinct fg_product_code from fg_products').map { |g| [g.fg_product_code] }
    extended_fg_codes = ExtendedFg.find_by_sql('select distinct extended_fg_code from extended_fgs').map { |g| [g.extended_fg_code] }
    order_product_codes = OrderProductType.find_by_sql('select distinct order_product_code from order_product_types').map { |g| [g.order_product_code] }
    order_number_observer  = {:updated_field_id => "customer_party_role_id_cell",
                              :remote_method => 'load_detail_order_number_changed',
                              :on_completed_js => combos_js_for_orders ["load_detail_order_number"]}

    session[:load_detail_form][:order_number_observer] = order_number_observer

#	combo lists for table: orders

    order_numbers = nil
    customer_party_role_ids = nil

#    order_numbers = load_detail.fin


    if load_detail == nil||is_create_retry
      customer_party_role_ids = ["Select a value from order_number"]
    else
      customer_party_role_ids = LoadDetail.customer_party_role_ids_for_order_number(load_detail.order.order_number)
    end

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (fg_products_id) on related table: fg_products
#	----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'fg_product_code',
                         :settings => {:list => fg_product_codes}}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (order_id) on related table: orders
#	----------------------------------------------------------------------------------------------
    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'order_number',
                         :settings => {:list => order_numbers},
                         :observer => order_number_observer}

    field_configs[2] =  {:field_type => 'DropDownField',
                         :field_name => 'customer_party_role_id',
                         :settings => {:list => customer_party_role_ids}}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (extended_fgs_id) on related table: extended_fgs
#	----------------------------------------------------------------------------------------------
    field_configs[3] =  {:field_type => 'DropDownField',
                         :field_name => 'extended_fg_code',
                         :settings => {:list => extended_fg_codes}}

    field_configs[4] = {:field_type => 'TextField',
                        :field_name => 'dispatched_quantity'}

    field_configs[5] = {:field_type => 'TextField',
                        :field_name => 'required_quantity'}

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (order_product_type_id) on related table: order_product_types
#	-----------------------------------------------------------------------------------------------------
    field_configs[6] =  {:field_type => 'DropDownField',
                         :field_name => 'order_product_code',
                         :settings => {:list => order_product_codes}}


    field_configs[7] = {:field_type => 'DateTimeField',
                        :field_name => 'price_timestamp'}

    field_configs[8] = {:field_type => 'TextField',
                        :field_name => 'marketing_org'}

    field_configs[9] = {:field_type => 'TextField',
                        :field_name => 'commodity_code'}

    field_configs[10] = {:field_type => 'TextField',
                         :field_name => 'marketing_variety_code'}

    field_configs[11] = {:field_type => 'TextField',
                         :field_name => 'old_pack_code'}

    field_configs[12] = {:field_type => 'TextField',
                         :field_name => 'brand_code'}

    field_configs[13] = {:field_type => 'TextField',
                         :field_name => 'size_ref'}

    field_configs[14] = {:field_type => 'TextField',
                         :field_name => 'grade_code'}

    field_configs[15] = {:field_type => 'TextField',
                         :field_name => 'inventory_code'}

    field_configs[16] = {:field_type => 'TextField',
                         :field_name => 'target_market_code'}

    field_configs[17] = {:field_type => 'TextField',
                         :field_name => 'puc'}

    field_configs[18] = {:field_type => 'TextField',
                         :field_name => 'old_fg_code'}

    field_configs[19] = {:field_type => 'TextField',
                         :field_name => 'pallet_format_product_code'}

    field_configs[20] = {:field_type => 'TextField',
                         :field_name => 'pc_code'}

    field_configs[21] = {:field_type => 'TextField',
                         :field_name => 'cold_store_type_code'}

    field_configs[22] = {:field_type => 'TextField',
                         :field_name => 'iso_week'}

    field_configs[23] = {:field_type => 'TextField',
                         :field_name => 'season_code'}

    field_configs[24] = {:field_type => 'TextField',
                         :field_name => 'pick_reference'}

    field_configs[25] = {:field_type => 'TextField',
                         :field_name => 'inspection_type_code'}

    field_configs[26] = {:field_type => 'TextField',
                         :field_name => 'label_code'}

    field_configs[27] = {:field_type => 'TextField',
                         :field_name => 'complex'}

    field_configs[28] = {:field_type => 'TextField',
                         :field_name => 'available_quantities'}

    field_configs[29] = {:field_type => 'TextField',
                         :field_name => 'price'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (uom_id) on related table: uoms
#	----------------------------------------------------------------------------------------------
    field_configs[30] =  {:field_type => 'DropDownField',
                          :field_name => 'uom_code',
                          :settings => {:list => uom_codes}}

    field_configs[31] = {:field_type => 'TextField',
                         :field_name => 'sequence_number'}

    field_configs[32] = {:field_type => 'TextField',
                         :field_name => 'cartons_lookup_sql'}

    build_form(load_detail, field_configs, action, 'load_detail', caption, is_edit)

  end


  def build_load_detail_search_form(load_detail, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:load_detail_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    order_numbers = LoadDetail.find_by_sql('select distinct order_number from load_detail').map { |g| [g.order_number] }
    order_numbers.unshift("<empty>")
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'order_number',
                         :settings => {:list => order_numbers}}

    build_form(load_detail, field_configs, action, 'load_detail', caption, false)

  end


  def build_load_detail_grid(data_set, can_edit, can_delete)


    column_configs = Array.new
    if !session[:current_viewing_order]
    grid_command =    {:field_type=>'link_window_field',:field_name =>'create_load_details',
                                 :settings =>
                                {
                                 :host_and_port =>request.host_with_port.to_s,
                                 :controller =>request.path_parameters['controller'].to_s,
                                 :target_action =>'create_load_details',
                                 :link_text => 'create_load_details',
                                 :id_value=>'id'
                                 }}
    column_configs[column_configs.length] = {:field_type => 'link_window', :field_name => 'select',:col_width=>100,
                                             :settings =>
                                                     {:link_text => 'select_pallets',
                                                      :target_action => 'select_load_pallets',
                                                      :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view_pallets',:col_width=>100,
                                               :settings =>
                                                       {:link_text => 'pallets',
                                                        :target_action => 'view_pallets',
                                                        :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'set_req_qty',:col_width=>150,
                                               :settings =>
                                                       {:link_text => 'set_required_qty',
                                                        :target_action => 'set_required_quantity',
                                                        :id_column => 'id'}}
    else
      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view_pallets',:col_width=>40,
                                               :settings =>
                                                       {:link_text => 'view_pallets',
                                                        :target_action => 'view_pallets',
                                                        :id_column => 'id'}}

    end
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sequence_number',:column_caption=>'seq_num',:col_width=>75}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'required_quantity',:column_caption=>'Required',:col_width=>75}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'actual_quantity',:column_caption=>'Actual',:col_width=>67}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'available_quantities',:column_caption=>'Available',:col_width=>75}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'holdover_quantity',:column_caption=>'holdover',:col_width=>75}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sub_total',:col_width=>78}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'price',:col_width=>64}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'commodity_code',:column_caption=>'commodity',:col_width=>85}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'marketing_variety_code',:column_caption=>'marketing_variety',:col_width=>120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'brand_code',:column_caption=>'brand',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'old_pack_code',:column_caption=>'old_pack',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'size_ref',:column_caption=>'size',:col_width=>50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'target_market_code',:column_caption=>'target_market',:col_width=>120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'grade_code',:column_caption=>'grade',:col_width=>50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_code',:column_caption=>'inventory',:col_width=>110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'puc',:col_width=>50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'marketing_org',:col_width=>110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'old_fg_code',:col_width=>200}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_format_product_code',:col_width=>125}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pc_code',:col_width=>150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}

#    set_grid_min_height(600)

    set_grid_min_width(850)
    hide_grid_client_controls()
     get_data_grid(data_set,column_configs,nil,grid_command)
  end

   def build_pallets_grid(data_set, can_edit, can_delete)

     column_configs = Array.new
     if !session[:current_viewing_order]
      if can_delete
           column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'remove', :col_width=>101,
                                                      :settings =>
                                                              {:link_text => 'remove_from_load',
                                                               :target_action => 'remove_load_detail_id',
                                                               :id_column => 'id'}}
         end

         if can_edit
           column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'set_holdover', :col_width=>110,
                                                      :settings =>
                                                              {:link_text => 'set_holdover',
                                                               :target_action => 'set_holdover',
                                                               :id_column => 'id'}}

           column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'edit',:col_width=> 34,
                                                                    :settings =>
                                                                            {:link_text => 'edit',
                                                                             :target_action => 'edit_pallet',
                                                                              :id_column => 'id'}}
         end
      end
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pallet_number',:col_width=>140}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks1',:column_caption=> Globals.get_column_captions['remarks1'],:col_width=>160}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks2',:column_caption=> Globals.get_column_captions['remarks2'],:col_width=>160}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks3',:column_caption=> Globals.get_column_captions['remarks3'],:col_width=>160}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'carton_quantity_actual',:column_caption=>'actual_qty',:col_width=>85}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'holdover',:col_width=>90}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'holdover_quantity',:column_caption=>'holdover_qty',:col_width=>120}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'oldest_pack_date_time',:col_width=>160}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'build_status',:col_width=>90}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'commodity_code',:column_caption=>'commodity',:col_width=>90}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'marketing_variety_code',:col_width=>150}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'target_market_code',:column_caption=>'target_market',:col_width=>215}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'grade_code',:column_caption=>'grade',:col_width=>60}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'iso_week_code',:col_width=>130}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'season_code',:column_caption=>'season',:col_width=>100}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pallet_format_product_code',:col_width=>190}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pc_code',:col_width=>160}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks4',:column_caption=> Globals.get_column_captions['remarks4'],:col_width=>160}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks5',:column_caption=> Globals.get_column_captions['remarks5'],:col_width=>160}
               column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'id'}

     get_data_grid(data_set,column_configs,MesScada::GridPlugins::Fg::PalletsGridPlugin.new(self,request))

   end

  def build_hold_over_form(pallet, action, caption, is_edit = nil, is_create_retry = nil)
       @load_detail=LoadDetail.find("#{pallet.load_detail_id}")

       field_configs = Array.new
         holdover_quantity= pallet.holdover_quantity
         field_configs[0] = {:field_type => 'CheckBox',
                             :field_name => 'holdover'}

         field_configs[1] = {:field_type => 'LabelField',
                             :field_name => 'actual_cartons',
                             :settings => {
                                  :show_label => true,

                                  :is_separator => false,
                                  :static_value => @load_detail.set_actual_carton_count}}



        field_configs[2] = {:field_type => 'TextField',
                            :field_name => 'holdover_quantity'}


    build_form(pallet, field_configs, action, 'pallet', caption, is_edit)

  end


    def  build_required_quantity_form(load_detail, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:order_product_form]= Hash.new

    field_configs = Array.new

      field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'sequence_number'}


     field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'actual_quantity'}


    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'available_quantities'}


     field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'required_quantity'}


    build_form(load_detail, field_configs, action, 'load_detail', caption, is_edit)

  end

end


