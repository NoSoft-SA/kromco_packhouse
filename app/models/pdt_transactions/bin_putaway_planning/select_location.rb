class SelectLocation < PDTTransactionState

  def initialize(parent)
    @parent = parent
  end

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"static_text", :name=>"msg",:value=>"Location not found OR Full"}

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

    if location.loading_out
      result_screen = PDTTransaction.build_msg_screen_definition("Location is in a loading_out state.", nil, nil, nil)
      return result_screen
    end

    @parent.location_code = location.location_code
    @parent.location_id = location.id

    @parent.spaces_left = Location.get_spaces_in_location(@parent.location_code, @parent.scanned_bins.length) if @parent.location_code

    error = validate_location

    if error
      result_screen = PDTTransaction.build_msg_screen_definition(error, nil, nil, nil)
      return result_screen
    else
      self.parent.clear_active_state
      next_state = BinPutawayScanning.new(@parent)
      self.parent.set_active_state(next_state)
      return next_state.process_scanned_bins
    end


  end

  def validate_location
    scanned_parent_location = ActiveRecord::Base.connection.select_one("
               select parent_location_code from locations where location_code = '#{@parent.location_code}'")['parent_location_code']

    if scanned_parent_location.to_s.upcase != @parent.coldroom.to_s.upcase
      return "Location does not belong to selected parent location."
    end

     if @parent.spaces_left && @parent.spaces_left.to_i <= 0
      return  "Location does not have enough space."
    end

    return nil

  end

end
