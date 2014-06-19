class Stock < PDTTransaction
  attr_accessor :location_code, :stock_take_id, :location_id

  def scan_location
    build_default_screen
  end

  def build_default_screen
    field_configs                       = Array.new
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'location_barcode', :is_required=>'true'}
    buttons                             = {"B1Label"=>"", "B1Enable"=>"false", "B1Submit"=>"scan_location_submit", "B2Label"=>"", "B2Enable"=>"false", "B3Submit"=>"", "B3Enable"=>"false", "B3Submit"=>""}
    screen_attributes                   = {:auto_submit=>"true", :auto_submit_to=>"scan_location_submit", :content_header_caption=>"scan location"}
    result_screen                       = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

  def scan_location_submit
    location_barcode = self.pdt_screen_def.get_control_value("location_barcode").to_s
    locations        = Location.find_by_sql("SELECT * FROM locations WHERE location_barcode = '#{location_barcode}'")
    if locations.empty?
      return PDTTransaction.build_msg_screen_definition("Location not found", nil, nil, nil)
    else
      location    = locations[0]
      stock_takes = StockTake.find_by_sql("SELECT * FROM stock_takes WHERE location_id = '#{location.id}' AND completed_on IS NULL AND cancelled_date_time IS NULL ")
      if stock_takes.empty?
        stock_take                    = StockTake.new
        stock_take.location_id        = location.id
        stock_take.created_on         = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
        stock_take.user_name          = self.pdt_screen_def.user
        stock_take.created_by         = self.pdt_screen_def.user
        stock_take.created_ip_address =self.pdt_screen_def.ip
        stock_take.create
        @location_code = location.location_code
        @stock_take_id = stock_take.id
        @location_id   = location.id

        stock_items    = StockItem.find_by_sql("SELECT * FROM stock_items WHERE location_code = '#{location.location_code}'")
        if !stock_items.empty?
          for stock_item in stock_items
            location_before_stock_take                     = LocationBeforeStockTake.new
            location_before_stock_take.stock_take_id       = self.stock_take_id
            location_before_stock_take.stock_item_id       = stock_item['id']
            location_before_stock_take.inventory_reference = stock_item['inventory_reference']
            location_before_stock_take.create
          end
        end

      else
        stock_take     = stock_takes[0]
        @location_code = location.location_code
        @stock_take_id = stock_take.id
      end
    end
    next_state = PalletStockScanning.new(self)
    self.set_active_state(next_state)
    return next_state.build_default_screen

  end

  def qty_pallets_in_location?()
    qty_pallets_in_location = LocationBeforeStockTake.find_by_sql("SELECT COUNT (*) FROM location_before_stock_takes WHERE stock_take_id = '#{self.stock_take_id}'")[0]['count']
    return qty_pallets_in_location
  end

  def qty_correct_pallets_scanned?()
    qty_correct_pallets_scanned = LocationCorrectStock.find_by_sql("SELECT COUNT (*) FROM location_correct_stocks WHERE stock_take_id = '#{self.stock_take_id}'")[0]['count']
    return qty_correct_pallets_scanned
  end

  def qty_error_pallets_scanned?()
    qty_error_correct_pallets_scanned = LocationErrorStock.find_by_sql("SELECT COUNT (*) FROM location_error_stocks WHERE stock_take_id = '#{self.stock_take_id}'")[0]['count']
    return qty_error_correct_pallets_scanned
  end

  def qty_forced_moves_in_progress?()
    qty_forced_moves_in_progress = LocationForcedMove.find_by_sql("SELECT COUNT (*) FROM location_forced_moves
                                                                  WHERE location_forced_moves.stock_take_id = #{self.stock_take_id} and location_forced_moves.completed_on IS NULL")[0]['count']

    return qty_forced_moves_in_progress
  end

  def qty_forced_moves_done?()

    qty_forced_moves_done = LocationForcedMove.find_by_sql("SELECT COUNT (*) FROM location_forced_moves                                                        
                                                        WHERE location_forced_moves.stock_take_id = #{self.stock_take_id} and location_forced_moves.completed_on IS NOT NULL ")[0]['count']

    return qty_forced_moves_done
  end

  def is_complete?()
    if qty_pallets_in_location?() == qty_correct_pallets_scanned?()
      return true
    else
      return false
    end
  end

  def complete_prompt()
    missing_stocks = get_missing_stocks()
    missing_pallets=missing_stocks.length

    field_configs                       = Array.new
    question                            = "Are you sure you want to complete stock_take?"
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"stock_take", :value=>question}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"location", :value=>self.location_code}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"pallets_in_location ", :value=>self.qty_pallets_in_location?}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"correct_pallets_scanned", :value=>self.qty_correct_pallets_scanned?}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"error_pallets_scanned", :value=>self.qty_error_pallets_scanned?}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"forced_moves_in_progress", :value=>self.qty_forced_moves_in_progress?}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"forced_moves_completed", :value=>self.qty_forced_moves_done?}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"missing pallets", :value=>missing_pallets}
    screen_attributes                   = {:auto_submit=>"false", :content_header_caption=>"complete_stock_take"}
    buttons                             = {"B3Label"=>"Clear", "B2Label"=>"yes", "B2Submit"=>"complete_confirmed", "B1Submit"=>"complete_unconfirmed", "B1Label"=>"no", "B1Enable"=>"true", "B2Enable"=>"true", "B3Enable"=>"false"}
    plugins                             = Array.new
    #plugins[plugins.length] = {:class_name=>'LabelPlugin',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
    result_screen_def                   = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def
  end

  def complete_confirmed
    missing_stocks = get_missing_stocks()
    if  !missing_stocks.empty?
      for inventory_reference in missing_stocks
        location_missing_stock                     = LocationMissingStock.new
        location_missing_stock.inventory_reference = inventory_reference
        #location_missing_stock.missing_reason =
        location_missing_stock.stock_take_id       = self.stock_take_id
        location_missing_stock.create
      end
    end
    stock_take                      = StockTake.find(self.stock_take_id)
    stock_take.completed_on         = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
    stock_take.completed_by         = self.pdt_screen_def.user
    stock_take.completed_ip_address = self.pdt_screen_def.ip
    stock_take.update
    self.set_transaction_complete_flag
    field_configs                       = Array.new
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"STOCK TAKE COMPLETED SUCCESSFULLY"}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"location", :value=>self.location_code}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"pallets_in_location ", :value=>self.qty_pallets_in_location?}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"correct_pallets_scanned", :value=>self.qty_correct_pallets_scanned?}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"error_pallets_scanned", :value=>self.qty_error_pallets_scanned?}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"forced_moves_in_progress", :value=>self.qty_forced_moves_in_progress?}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"forced_moves_completed", :value=>self.qty_forced_moves_done?}
    if !missing_stocks.empty?
      field_configs[field_configs.length] = {:type=>"static_text", :name=>"missing_pallets", :value=>missing_stocks.length.to_s}
    end

    screen_attributes = {:auto_submit=>"false", :content_header_caption=>"stock_take_completed"}
    buttons           = {"B3Label"=>"Clear", "B2Label"=>"", "B2Submit"=>"", "B1Submit"=>"", "B1Label"=>"", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins           = Array.new
    #plugins[plugins.length] = {:class_name=>'LabelPlugin',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def

  end

  def complete_unconfirmed
    next_state = PalletStockScanning.new(self)
    self.set_active_state(next_state)
    return next_state.build_default_screen
  end

  def get_missing_stocks

    inventory_references     = LocationBeforeStockTake.find_by_sql("select location_before_stock_takes.inventory_reference
                                from location_before_stock_takes
                                where location_before_stock_takes.inventory_reference not in (
                                select inventory_reference from location_correct_stocks where location_correct_stocks.stock_take_id =#{self.stock_take_id}  UNION
                                select inventory_reference from location_error_stocks where location_error_stocks.stock_take_id =#{self.stock_take_id})
                                and location_before_stock_takes.stock_take_id =#{self.stock_take_id}")
    inventory_references_ary = Array.new
    for reference in inventory_references
      inventory_reference = reference['inventory_reference']
      inventory_references_ary << inventory_reference
    end
    return inventory_references_ary
  end


end