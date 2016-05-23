class PutAwayPallet < PDTTransaction

  attr_accessor :pallet_number, :location_code, :to_location_list, :uncouple_load

  def put_away_pallet()
    if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
      build_default_screen
    else
      put_away_pallet_submit
    end
  end

  def build_default_screen()
    field_configs = Array.new
     field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_pallet",:is_required=>"true"}

     screen_attributes = {:auto_submit=>"true",:content_header_caption=>"scan put away pallet",:auto_submit_to=>'put_away_pallet_submit'}
     buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"put_away_pallet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
     plugins = nil
     result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

     return result_screen_def
  end

  def put_away_pallet_submit()
    @pallet_number = self.pdt_screen_def.get_control_value("scan_pallet").to_s.strip
    valid_msg = validate_input
    if valid_msg.to_s.strip != ""
      error_msg_array = valid_msg.to_s.split("|")
      field_configs = Array.new
      error_msg_array.each do | err|
        if err.to_s.strip != ""
          field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>err.to_s}
        end
      end
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error messages"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"put_away_pallet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    else
      pallet = Pallet.find_by_pallet_number(@pallet_number)

      pfp_rec = PalletFormatProduct.find_by_pallet_format_product_code(pallet.pallet_format_product_code)
      raise "PFP #{pallet.pallet_format_product_code} does not exits "   if !pfp_rec

      oldest_carton = Carton.find_by_sql("select * from cartons where pallet_id=#{pallet.id} order by id desc limit 1")[0]

      return PDTTransaction.build_msg_screen_definition("pallet has no cartons")  if !oldest_carton

      extended_fg = ExtendedFg.find_by_extended_fg_code(oldest_carton.extended_fg_code)
      fg_product = FgProduct.find_by_fg_product_code(extended_fg.fg_code)
      item_pack_product = fg_product.item_pack_product
      fg_mark = FgMark.find_by_fg_mark_code(extended_fg.fg_mark_code)
      mark = Mark.find_by_mark_code(fg_mark.tu_mark_code)
      assignment = 'STORAGE'
      assignment = 'RECOOL' if pallet.store_type_code = "cold_store"

      load_pallet_condition = ""
      load_pallet_condition = " and (locations.location_code NOT like '%PART_PALLETS%')" if pallet.load_detail_id
      
      query = " SELECT DISTINCT location_setups.priority,location_setups.location_code
                from location_setups
                JOIN locations on location_setups.location_id=locations.id
                where ((location_setups.extended_fg_code='ALL' or location_setups.extended_fg_code='#{oldest_carton.extended_fg_code}')
                and (location_setups.order_code='ALL' or location_setups.order_code='#{oldest_carton.order_number}')
                and (location_setups.commodity_code='ALL' or location_setups.commodity_code='#{item_pack_product.commodity_code}')
                and (location_setups.variety_code='ALL' or location_setups.variety_code='#{item_pack_product.marketing_variety_code}')
                and (location_setups.brand_code='ALL' or location_setups.brand_code='#{mark.brand_code}')
                and (location_setups.old_pack_code='ALL' or location_setups.old_pack_code='#{oldest_carton.old_pack_code}')
                and (location_setups.size_ref_code='ALL' or location_setups.size_ref_code='#{item_pack_product.size_ref}')
                and (location_setups.target_market_code='ALL' or location_setups.target_market_code='#{oldest_carton.target_market_code}')
                and (location_setups.inventory_code='ALL' or location_setups.inventory_code='#{oldest_carton.inventory_code}')
                and (location_setups.grade_code='ALL' or location_setups.grade_code='#{item_pack_product.grade_code}')
                and (location_setups.org_short_description='ALL' or location_setups.org_short_description='#{oldest_carton.organization_code}')
                and (location_setups.stack_type_code='ALL' or location_setups.stack_type_code='#{pfp_rec.stack_type_code}')
                and (location_setups.unit_pack_product_code='ALL' or location_setups.unit_pack_product_code='#{fg_product.unit_pack_product_code}')
                and (location_setups.carton_pack_product_code='ALL' or location_setups.carton_pack_product_code='#{fg_product.carton_pack_product_code}')
                and (location_setups.build_status='ALL' or location_setups.build_status='#{pallet.build_status}')
                and (location_setups.pallet_format_product_code='ALL' or location_setups.pallet_format_product_code='#{pallet.pallet_format_product_code}')
                 and (locations.unavailable= false or locations.unavailable is null)
                and (locations.units_in_location <  locations.location_maximum_units)
                 #{load_pallet_condition}
                and (locations.current_job_reference_id is null) and location_setups.assignment = '#{assignment}'
                )
                order by location_setups.priority DESC
      "
#               and (location_setups.pallet_format_product_id=#{pallet.pallet_format_product_id} or location_setups.pallet_format_product_id='#{pallet.pallet_format_product_id}')
  puts query 
      @to_location_list = LocationSetup.find_by_sql(query).map{|g|g.location_code}.uniq
      return PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["No valid locations available "," to do putaway for this pallet"]) if @to_location_list.length == 0
        next_state = ScanPutawayLocation.new(self)        

      result_screen = next_state.build_default_screen
      self.set_active_state(next_state)
      return result_screen
    end
  end

  def validate_input()
    return valid_pallet?

  end

  def valid_pallet?()
    pallet_num = PDTFunctions.extract_pallet_num(@pallet_number)
    if !pallet_num.upcase.include?("INVALID")
      pallet = Pallet.find_by_pallet_number(pallet_num.to_s.strip)
      if pallet
        @pallet_number = pallet.pallet_number
         return nil 
      else
        return "No pallet found form scanned pallet_number"
      end
    else
      return "The Scanned Pallet Number is not valid!"
    end
  end

  def putaway_trans()
    ActiveRecord::Base.transaction do

      remove_probe_from_pallet
      
      Inventory.move_stock('PUT_AWAY_PALLET','PUT_AWAY_PALLET',@location_code,[@pallet_number])
      
      if @uncouple_load == true
        uncouple_load()
      end
     
#      set_transaction_complete_flag
#      field_configs = Array.new
#      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"Put away pallet transaction completed successifully!"}
#      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"putaway pallet transaction complete"}
#      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"uncouple_pallet_no","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
#      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
      set_repeat_process_flag
    end
  end

  def remove_probe_from_pallet
    pallet = Pallet.find_by_pallet_number(@pallet_number)
    pallet_probe = PalletProbe.find_by_pallet_id(pallet.id)
    if(pallet_probe)
      job = Job.find(pallet_probe.job_id)
      if( job && pallet_probe &&  job.current_job_status == "JOB CREATED")
        pallet_probe.destroy
        probe = Probe.find(pallet_probe.probe_id)
        probe.update_attribute(:probe_status_code, "NOT IN USE")
      end
    end
  end

  def uncouple_load
    
  end

  def get_stock_item_current_location
    location = nil
    stock_item = StockItem.find_by_inventory_reference(@pallet_number)
    if stock_item
      stocks = InventoryTransactionStock.find_by_sql("SELECT * FROM inventory_transaction_stocks where stock_item_id = '#{stock_item.id}' order by id desc")
      if stocks.length > 0
        location = stocks[0].location_to
      end
    end
    return location
  end
end
