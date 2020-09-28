class ScanLoadPallet < PDTTransactionState

  def initialize(parent)
    self.parent = parent

    @current_scanned_pallet_index = 0
  end


  def build_default_screen

    field_configs = Array.new
    scand= "'#{self.parent.scanned_pallets.length().to_s}' pallets of '#{self.parent.pick_list_pallets.length().to_s}'"

    field_configs[field_configs.length] = {:type=>"static_text", :name=>"scanned", :value=>"'#{scand}'"}


	  field_configs[field_configs.length()] = {:type=>"text_box", :name=>"pallet_number", :is_required=>"true", :scan_only=>"true"}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"load_number", :value=>@parent.load_number}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"load_order_id", :value=>@parent.load_order_id.to_s}
    screen_attributes = {:auto_submit=>"true", :auto_submit_to=>"pallet_scanned",:cache_screen => true}
    buttons = {"B3Label"=>"next", "B3Submit"=>"next_pallet", "B2Label"=>"scan_pallet", "B2Submit"=>"pallet_scanned", "B1Submit"=>"previous_pallet", "B1Label"=>"previous", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}

    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def pallet_scanned
    scanned_pallet_number = self.parent.pdt_screen_def.get_control_value("pallet_number")
    pallet_num = PDTFunctions.extract_pallet_num(scanned_pallet_number)

     if pallet_num.upcase().index("INVALID")
      return PDTTransaction.build_msg_screen_definition(pallet_num, nil, nil, nil)
     end

    if !@parent.pick_list_pallets.include?(pallet_num)
      return PDTTransaction.build_msg_screen_definition("scanned pallet does not belong to this pick list ", nil, nil, nil)
    end

    pallet = Pallet.find_by_pallet_number(pallet_num)
    stock_item =StockItem.find_by_inventory_reference(pallet_num.to_s)

    #--------Load-Truck:  If the status is FAILED when the truck is loaded, the system must give the error message and not allow the user to proceed with the load.
    if !pallet.is_depot_pallet
        deliveries_for_pallet_carton_groups = Carton.find_by_sql("
                    select cartons.farm_code,cartons.season_code,cartons.commodity_code,track_indicators.rmt_variety_code
                    from cartons
                    join track_indicators on track_indicators.track_indicator_code=cartons.track_indicator_code
                    where cartons.pallet_number='#{scanned_pallet_number}'
                    group by cartons.farm_code,cartons.season_code,cartons.commodity_code,track_indicators.rmt_variety_code")

        deliveries_for_pallet_carton_groups.each do |delivery_for_grp|
          if(mrl_error = Delivery.mrl_passed_for_load_pallet?(delivery_for_grp.farm_code,delivery_for_grp.season_code,delivery_for_grp.rmt_variety_code,delivery_for_grp.commodity_code))
            return PDTTransaction.build_msg_screen_definition(nil, nil, nil, mrl_error)
          end
        end
    end

    #only export pallets (first part of if clause) needs to be inspected and passed in order to be eligible for a load
    if pallet.load_detail.load_order.load.load_voyages.size > 0 && pallet.qc_result_status!="PASSED"
     return PDTTransaction.build_msg_screen_definition("#{pallet_num }:QC RESULT STATUS  is not PASSED", nil, nil, nil)
    end

    if @parent.scanned_pallets.include?(pallet_num.to_s)
      return PDTTransaction.build_msg_screen_definition("pallet #{pallet_num.to_s} already scanned!!!! ", nil, nil, nil)
    end

    if pallet.target_market_code=="P9_PART PALLETS"
      return PDTTransaction.build_msg_screen_definition("target_market_code is P9_PART PALLETS ", nil, nil, nil)
    end

    if   stock_item.location_code.upcase.index("PART_PALLETS")
      return PDTTransaction.build_msg_screen_definition("location_code has  PART_PALLETS", nil, nil, nil)
    end

    @parent.scanned_pallets.push(pallet_num.to_s)
    if (self.parent.scanned_pallets.length == self.parent.pick_list_pallets.length)
      self.parent.set_active_state(nil)
      self.parent.load_truck_trans()
    else
      @current_scanned_pallet_index+=1
      return build_default_screen
    end


  end

  def show_loaded_pallets
    list = get_loaded_pallets()
    return build_pallets_list_screen(list, "Currently Loaded Pallets")
  end


  def scan_pallet_to_load
    build_default_screen
  end


  def previous_pallet()
    if (on_first?)
      buttons['B1Enable'] = false
    else
      @current_pallet_index -= 1
    end
    build_default_screen
  end

  def next_pallet
    if (on_last?)
    else
      @current_pallet_index += 1
    end
    build_default_screen
  end

  def on_last?
    @current_pallet_index == self.parent.scanned_pallets.length() -1
  end

  def on_first?
    @current_pallet_index == 0
  end


  def show_not_yet_loaded_pallets
    list = get_not_loaded_pallets()
    return build_pallets_list_screen(list, "Currently Not Loaded Pallets")
  end

  def not_loaded_pallets
    not_loaded_list = get_not_loaded_pallets
    return not_loaded_list
  end

  def get_loaded_pallets
    loaded_list = self.parent.scanned_pallets
    return loaded_list
  end


  def get_not_loaded_pallets
    return self.parent.pick_list_pallets - self.parent.scanned_pallets
  end


  def build_pallets_list_screen(pallets_list, caption)
    field_configs = Array.new
    pallets_list.each do |pallet_num|
      field_configs[field_configs.length] = {:name=>'pallet_number', :type=>'text_line', :value=>pallet_num.to_s, :is_required=>'true'}
    end
    buttons = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=> caption, :auto_submit=>"false"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
  end


end
