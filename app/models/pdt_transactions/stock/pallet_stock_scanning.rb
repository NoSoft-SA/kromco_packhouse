class PalletStockScanning < PDTTransactionState

  def initialize(parent)
    self.parent = parent
    @parent     = self.parent
  end

  def build_default_screen

    field_configs                       = Array.new
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"location", :value=>@parent.location_code}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"pallets_in_location", :value=>@parent.qty_pallets_in_location?()}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"correct_pallets_scanned", :value=>@parent.qty_correct_pallets_scanned?()}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"error_pallets_scanned", :value=>@parent.qty_error_pallets_scanned?()}
   field_configs[field_configs.length] = {:type=>"static_text", :name=>"forced_moves_in_progress", :value=>@parent.qty_forced_moves_in_progress?()}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"forced_moves_completed", :value=>@parent.qty_forced_moves_done?()}
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"pallet_number", :is_required=>'true'}           
    screen_attributes                   = {:auto_submit=>"true", :auto_submit_to=>"pallet_scanned_submit", :content_header_caption=>"scan pallets"}
    buttons                             = {"B1Label"=>"", "B1Enable"=>"false", "B1Submit"=>"pallet_scanned_submit", "B2Label"=>"", "B2Enable"=>"false", "B3Submit"=>"", "B3Enable"=>"false", "B3Submit"=>""}
    result_screen                       = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

  def pallet_scanned_submit

    pallet       = self.pdt_screen_def.get_control_value("pallet_number").to_s
    pallet_number=PDTFunctions.extract_pallet_num(pallet)

    if pallet_number.upcase.include?("INVALID")
      return PDTTransaction.build_msg_screen_definition("not a valid pallet_number "+ "#{pallet_number}", nil, nil, nil)
      build_default_screen
    end
    already_scanned_pallet = is_scanned?(pallet_number)
    if already_scanned_pallet !=nil
      return PDTTransaction.build_msg_screen_definition("#{already_scanned_pallet} ", nil, nil, nil)
      build_default_screen
    end
    msg = in_progress?(pallet_number)
    if msg == nil
      #--------------------------------------------------------------------
      sequences=Array.new
      cartons = Carton.find_by_sql("SELECT count(*) as count, pallets.pt_product_characteristics as pt_product_characteristics,
      cartons.fg_code_old,cartons.puc, cartons.pick_reference, cartons.target_market_code, cartons.inventory_code, cartons.pallet_sequence_number,
      cartons.commodity_code, cartons.organization_code, cartons.variety_short_long, cartons.grade_code, cartons.old_pack_code, cartons.sell_by_code,
      cartons.remarks, marks.brand_code, min(pack_date_time) AS oldest_pack_date_time, public.cartons_per_pallets.cartons_per_pallet,
      pallets.build_status FROM cartons   INNER JOIN marks ON (cartons.carton_mark_code = marks.mark_code)
      INNER JOIN pallets ON (cartons.pallet_id = pallets.id)
      INNER JOIN public.fg_products ON (cartons.fg_product_code = public.fg_products.fg_product_code)
      LEFT OUTER JOIN public.cartons_per_pallets ON (public.fg_products.carton_pack_product_id = public.cartons_per_pallets.carton_pack_product_id)
      AND (pallets.pallet_format_product_code = public.cartons_per_pallets.pallet_format_product_code)
      WHERE pallets.pallet_number = '#{pallet_number.to_s}' GROUP BY pallets.pt_product_characteristics,
      cartons.fg_code_old, cartons.puc, cartons.pick_reference, cartons.target_market_code, cartons.inventory_code,
      cartons.pallet_sequence_number, cartons.commodity_code, cartons.organization_code, cartons.variety_short_long,
      cartons.grade_code, cartons.old_pack_code, cartons.sell_by_code, cartons.remarks, marks.brand_code, public.cartons_per_pallets.cartons_per_pallet,
      pallets.build_status ORDER BY count(*) DESC")
    if cartons.length != 0
      stock_item                          = StockItem.find_by_sql("SELECT * FROM stock_items WHERE inventory_reference = '#{pallet_number}'")[0]
      stock_take_scan                     =StockTakeScan.new
      stock_take_scan.status              = "SCANNED"
      stock_take_scan.stock_take_id       = @parent.stock_take_id
      stock_take_scan.inventory_reference = pallet_number
      stock_take_scan.created_on          = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
      stock_take_scan.stock_item_id       = stock_item['id']
      stock_take_scan.user_name           = self.pdt_screen_def.user
      stock_take_scan.create
      stock_take_scan
    end

    else
      return PDTTransaction.build_msg_screen_definition("#{msg} ", nil, nil, nil)
      build_default_screen
    end

    #if record is not found return false else return true
    result = in_this_location?(pallet_number)
    if result == true      
      next_state = PalletStockEvaluation.new(@parent, pallet_number,nil)
      self.parent.set_active_state(next_state)
      return next_state.build_default_screen

    else
      stock_items = StockItem.find_by_sql("SELECT * FROM stock_items WHERE inventory_reference= '#{pallet_number}'")
      if !stock_items.empty?
        stock_item = stock_items[0]
      end
      current_location = stock_item['location_code']
      next_state       = PalletStockEvaluation.new(@parent, pallet_number, current_location)
      self.parent.set_active_state(next_state)
      return next_state.build_default_screen

    end
  end

  def is_scanned?(pallet_number)
    inventory_reference = LocationCorrectStock.find_by_sql("SELECT * FROM location_correct_stocks WHERE inventory_reference = '#{pallet_number}'")
    if !inventory_reference.empty?
      msg1 = "#{inventory_reference[0]['inventory_reference']}" + ""+ " has been successfully scanned ,scan another pallet"
      return msg1
    else
      return nil
    end

  end


  def in_progress?(pallet_number)
    stock_take_scans = StockTakeScan.find_by_sql("SELECT * FROM stock_take_scans WHERE stock_take_id = '#{@parent.stock_take_id}' AND inventory_reference = '#{ pallet_number}'")
    if !stock_take_scans.empty?
      stock_take_scan = stock_take_scans[0]
      if stock_take_scan.status == "SCANNED"
        msg1 = "This pallet is being scanned by user:'#{stock_take_scan.user_name}'"
        return msg1
      else
        stock_take_scan.status != "RESCAN ALLOWED"
        msg2 = "This pallet has already been processed.Action was:" + "#{stock_take_scan.action}" + "User:" + "#{stock_take_scan.user_name}"
        return msg2
      end

      return nil
    end
  end

  def in_this_location?(pallet_number)
    location_before_stock_takes = LocationBeforeStockTake.find_by_sql("SELECT * FROM location_before_stock_takes WHERE stock_take_id = '#{@parent.stock_take_id}' AND inventory_reference = '#{pallet_number}'")
    if  location_before_stock_takes.empty?
      return false
    else
      return true
    end
  end

  def complete_stocktake
    self.parent.clear_active_state
    @parent.complete_prompt()
  end

  def show_original_pallets_in_location
    inventory_references = LocationBeforeStockTake.find_by_sql("SELECT inventory_reference FROM location_before_stock_takes WHERE stock_take_id = '#{self.parent.stock_take_id}'")
    field_configs        = Array.new
    for inventory_reference in inventory_references
      field_configs[field_configs.length] = {:name=>'pallet_num', :type=>'text_line', :value=>inventory_reference['inventory_reference'].to_s, :is_required=>'true'}
    end

    buttons           = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=> "original_pallets_in_location", :auto_submit=>"false"}
    plugins           =nil
    result_screen     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
  end

  def show_current_pallets_in_location
    inventory_references = StockItem.find_by_sql("SELECT inventory_reference FROM stock_items WHERE location_code = '#{self.parent.location_code}'")
    field_configs        = Array.new
    for inventory_reference in inventory_references
      field_configs[field_configs.length] = {:name=>'pallet_num', :type=>'text_line', :value=>inventory_reference['inventory_reference'].to_s, :is_required=>'true'}
    end

    buttons           = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=> "current_pallets_in_location", :auto_submit=>"false"}
    plugins           =nil
    result_screen     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

  end

  def show_scanned_error_pallets
    inventory_references = LocationErrorStock.find_by_sql("SELECT inventory_reference FROM location_error_stocks WHERE stock_take_id = '#{self.parent.stock_take_id}'")
    field_configs        = Array.new
    for inventory_reference in inventory_references
      field_configs[field_configs.length] = {:name=>'pallet_num', :type=>'text_line', :value=>inventory_reference['inventory_reference'].to_s, :is_required=>'true'}
    end

    buttons           = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=> "scanned_error_pallets", :auto_submit=>"false"}
    plugins           =nil
    result_screen     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

  end

  def show_scanned_correct_pallets
    inventory_references = LocationCorrectStock.find_by_sql("SELECT inventory_reference FROM location_correct_stocks WHERE stock_take_id = '#{self.parent.stock_take_id}'")
    field_configs        = Array.new
    for inventory_reference in inventory_references
      field_configs[field_configs.length] = {:name=>'pallet_num', :type=>'text_line', :value=>inventory_reference['inventory_reference'].to_s, :is_required=>'true'}
    end

    buttons           = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=> "scanned_correct_pallets", :auto_submit=>"false"}
    plugins           =nil
    result_screen     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

  end

  def show_missing_pallets
    missing_pallets = self.parent.get_missing_stocks
    field_configs   = Array.new
    for inventory_reference in missing_pallets
      field_configs[field_configs.length] = {:name=>'pallet_num', :type=>'text_line', :value=>inventory_reference.to_s, :is_required=>'true'}
    end

    buttons           = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=> "missing_pallets", :auto_submit=>"false"}
    plugins           =nil
    result_screen     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

  end

  def cancel_stock_take
    stock_take                     = StockTake.find(self.parent.stock_take_id)
    stock_take.cancelled_date_time = Time.now
    stock_take.update
    
    location_before_stock_takes_query = "delete from location_before_stock_takes where stock_take_id=#{self.parent.stock_take_id} "
    location_correct_stocks_query = "delete from location_correct_stocks where stock_take_id=#{self.parent.stock_take_id} "
    location_error_stocks_query = "delete from location_error_stocks where stock_take_id=#{self.parent.stock_take_id} "
    location_forced_moves_query = "delete from location_forced_moves where stock_take_id=#{self.parent.stock_take_id} "
    location_missing_stocks_query = "delete from location_missing_stocks where stock_take_id=#{self.parent.stock_take_id} "
    stock_take_scans_query = "delete from stock_take_scans where stock_take_id=#{self.parent.stock_take_id} "

    ActiveRecord::Base.connection.execute(location_before_stock_takes_query )
    ActiveRecord::Base.connection.execute(location_correct_stocks_query)
    ActiveRecord::Base.connection.execute(location_error_stocks_query)
    ActiveRecord::Base.connection.execute(location_forced_moves_query )
    ActiveRecord::Base.connection.execute(location_missing_stocks_query)
    ActiveRecord::Base.connection.execute(stock_take_scans_query)
#
    self.parent.set_transaction_complete_flag
    self.parent.clear_active_state
    field_configs                       = Array.new
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>"Stock Take Cancelled."}
    screen_attributes                   = {:auto_submit=>"false", :content_header_caption=>"Stock Take Cancelled"}
    buttons                             = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

  def scan_pallet
    field_configs                       = Array.new
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"location", :value=>@parent.location_code}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"pallets_in_location", :value=>@parent.qty_pallets_in_location?()}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"correct_pallets_scanned", :value=>@parent.qty_correct_pallets_scanned?()}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"error_pallets_scanned", :value=>@parent.qty_error_pallets_scanned?()}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"forced_moves_in_progress", :value=>@parent.qty_forced_moves_in_progress?()}
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"forced_moves_completed", :value=>@parent.qty_forced_moves_done?()}
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"pallet_number", :is_required=>'true'}
    screen_attributes                   = {:auto_submit=>"true", :auto_submit_to=>"pallet_scanned_submit", :content_header_caption=>"scan pallets"}
    buttons                             = {"B1Label"=>"", "B1Enable"=>"false", "B1Submit"=>"pallet_scanned_submit", "B2Label"=>"", "B2Enable"=>"false", "B3Submit"=>"", "B3Enable"=>"false", "B3Submit"=>""}
    result_screen                       = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end


end


  























