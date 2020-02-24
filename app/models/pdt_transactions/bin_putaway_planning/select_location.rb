class SelectLocation < PDTTransactionState

  def initialize(parent)
    @parent = parent
  end

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"msg",:value=>@parent.error_str}

    field_configs[field_configs.length] = {:type => "text_box", :name => "scan_location_barcode",
                                           :is_required => "true", :scan_only => "false", :scan_field => true,
                                           :submit_form => true}
    screen_attributes = {:auto_submit => "true", :auto_submit_to => "submit_selected_location", :cache_screen => true}
    buttons = {"B3Label" => "", "B2Label" => "", "B1Submit" => "submit_selected_location", "B1Label" => "submit", "B1Enable" => "false", "B2Enable" => "false", "B3Enable" => "false"}

    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def submit_selected_location
    location_barcode = self.pdt_screen_def.get_control_value("scan_location_barcode").strip
    location = Location.find_by_location_barcode(location_barcode)
    if !location
      result_screen = PDTTransaction.build_msg_screen_definition("Not a valid location barcode.", nil, nil, nil)
      return result_screen
    end

    error = validate_location(location)
    if error
      result_screen = PDTTransaction.build_msg_screen_definition(error, nil, nil, nil)
      return result_screen
    else
      @parent.location_code = location.location_code
      @parent.location_id = location.id
      @parent.spaces_left = Location.get_spaces_in_location(@parent.location_code, @parent.scanned_bins.length, @parent.qty_bins.to_i) if @parent.location_code

      self.parent.clear_active_state
      next_state = BinPutawayScanning.new(@parent)
      self.parent.set_active_state(next_state)
      return next_state.process_scanned_bins
    end


  end

  def validate_location(location)
    scanned_parent_location = ActiveRecord::Base.connection.select_one("
               select parent_location_code from locations
               where location_code = '#{location.location_code}'")['parent_location_code']

    if scanned_parent_location.to_s.upcase != @parent.coldroom.to_s.upcase
      return "Location does not belong to selected parent location,UNDO and scan another location."
    end

     if @parent.spaces_left && @parent.spaces_left.to_i <= 0
      return  "Location does not have enough space,UNDO and scan another location."
     end

    if location.loading_out
      return "Location is loading_out.Scan another one."
    end

    location_status = Location.check_location_status(location.location_barcode)
    if  location_status  != nil
      if location_status.upcase.index("SEALED")
        error = "Location is #{location_status} "
      elsif location_status == "GAS"
        error = "Location status is: GAS "
      end
      return error if error
    end

    return nil

  end

end
