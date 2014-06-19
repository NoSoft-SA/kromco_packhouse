class PalletStockEvaluation < PalletSequenceNavigator


  def build_sequence_screen()
    if self.on_last?()
      screen_definition = super
      temp = PdtScreenDefinition.new(screen_definition, nil, PdtScreenDefinition.const_get("ENTERDATA"), nil, nil) #"1.2.2a"
#      temp.controls[temp.controls.length()] = {:type=>"static_text", :name=>"location", :value=>self.parent.location_code}
      temp.controls[temp.controls.length()-1]['value'] = self.parent.location_code

      if @wrong_location == nil
        temp.controls[temp.controls.length()] = {:type=>"drop_down", :name=>"stock_item_result", :is_required=>"true", :list => ",                            ,'loc/fspec/ctns_correct','qty_ctn_differ','fspec_variance','loc/plt_mismatch'"}
      else
        temp.controls[temp.controls.length()] = {:type=>"static_text", :name=>"wrong_location", :value=>@wrong_location}
        temp.controls[temp.controls.length()] = {:type=>"drop_down", :name=>"stock_item_result", :is_required=>"true", :list => ",
                                                 ,'forced_move_in,other'"}
      end

      temp.buttons["B3Enable"] = "true"
      temp.buttons["B3Label"] = "save"
      temp.buttons["B3Submit"] = "submit_stock_item_result"

      result_screen = temp.get_output_xml()
      return result_screen
    else
      super
    end
  end

  def submit_stock_item_result
    stock_take_scans = StockTakeScan.find_by_sql("SELECT * FROM stock_take_scans WHERE stock_take_id = '#{self.parent.stock_take_id}'")
    stock_item_result = self.pdt_screen_def.get_control_value("stock_item_result").to_s
    wrong_location    = self.pdt_screen_def.get_control_value("wrong_location").to_s

    if @wrong_location !=nil
      if stock_item_result == "forced_move_in"
       do_forced_move()
      else
        stock_item_result == "other"
        log_stock_error('WRONG_LOCATION', @wrong_location)
        for stock_take_scan in stock_take_scans
#          stock_take_scan.destroy
        end

        self.parent.clear_active_state
        next_state = PalletStockScanning.new(@parent)
        @parent.set_active_state(next_state)
        return next_state.build_default_screen

      end

    else
      if stock_item_result == 'loc/fspec/ctns_correct'
        location_correct_stock = LocationCorrectStock.new
        location_correct_stock.location_id  = self.parent.location_id
        stock_item = StockItem.find_by_inventory_reference(@pallet_no)
        location_correct_stock.stock_item_id =  stock_item.id
        location_correct_stock.stock_take_id =  self.parent.stock_take_id
        location_correct_stock.user_name =  self.pdt_screen_def.user
        location_correct_stock.inventory_reference =@pallet_no
        location_correct_stock.ip_address = self.pdt_screen_def.ip
        location_correct_stock.create
        if self.parent.is_complete?()
          for stock_take_scan in stock_take_scans
#            stock_take_scan.destroy
          end
          self.parent.clear_active_state
          self.parent.complete_prompt()
        else
          for stock_take_scan in stock_take_scans
#            stock_take_scan.destroy
           end
          self.parent.clear_active_state
          next_state = PalletStockScanning.new(@parent)
          @parent.set_active_state(next_state)
          return next_state.build_default_screen
        end
      else
        log_stock_error(stock_item_result, wrong_location)
         for stock_take_scan in stock_take_scans
#          stock_take_scan.destroy
        end
        self.parent.clear_active_state
        next_state = PalletStockScanning.new(@parent)
        @parent.set_active_state(next_state)
        return next_state.build_default_screen

      end
    end
  end

  def log_stock_error(stock_item_result, location)
    stock_item_id = StockTakeScan.find_by_stock_take_id("#{self.parent.stock_take_id}").stock_item_id
    location_error_stock = LocationErrorStock.new
    location_error_stock.error_reason = stock_item_result
    location_error_stock.stock_take_id = self.parent.stock_take_id
    location_error_stock.user_name = self.pdt_screen_def.user
    location_error_stock.stock_item_id = stock_item_id
    location_error_stock.inventory_reference =@pallet_no
    location_error_stock.ip_address =self.pdt_screen_def.ip
    #location_stock_error.carton_quantity =
    location_error_stock.create
  end

  def do_forced_move()
    stock_take_scan = StockTakeScan.find_by_inventory_reference("#{@pallet_no}")
    stock_take_scan.status = "DONE"
    stock_take_scan.action = "FORCED MOVE IN"
    stock_take_scan.update
    location_forced_move = LocationForcedMove.new
    location_forced_move.completed_on = Time.now
    location_forced_move.stock_take_id = self.parent.stock_take_id
    location_forced_move.inventory_reference =self.pallet_no
    location_forced_move.create

    require "app/models/pdt_transactions/forced_move/forced_move.rb"
    forced_move = ForcedMove.new()
    forced_move.pdt_screen_def = PdtScreenDefinition.new(build_forced_move_screen, nil, PdtScreenDefinition.const_get("ENTERDATA"), self.pdt_screen_def.user, self.pdt_screen_def.ip)
    error_screen = forced_move.force_move_submit()

    if error_screen ==nil
#        stock_take_scan.destroy
      next_state = PalletStockScanning.new(@parent)
      self.parent.set_active_state(next_state)
      return next_state.build_default_screen
    else
#      stock_take_scan.destroy 
       return error_screen
    end
  end

  def build_forced_move_screen
    #-----------------------------------------------
    # Client side filtering
    #-----------------------------------------------
    location_barcode = Location.find_by_location_code(self.parent.location_code).location_barcode
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"pallet_number", :label=>"scan pallet", :value=>self.pallet_no, :is_required=>true}
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"scan_location", :label=>"scan location", :value=>location_barcode, :is_required=>true}
    screen_attributes = {:auto_submit=>"false", :content_header_caption=>"force move"}
    buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Label"=>"Submit", "B1Submit"=>"force_move_submit", "B1Enable"=>"true", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins = Array.new
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def
  end


  def initialize(parent, pallet_no, current_location)
    super(parent, pallet_no)
    @wrong_location = current_location
    location = self.parent.location_code
  end


end