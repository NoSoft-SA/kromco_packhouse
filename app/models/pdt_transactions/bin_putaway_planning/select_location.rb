class SelectLocation < PDTTransactionState

  def initialize(parent)
    @parent = parent
  end

  def build_default_screen
    field_configs = Array.new
  #ield_configs[field_configs.length] = {:type=>"static_text", :name=>"no matching location found OR location is full . Scan new location"}

    field_configs[field_configs.length] = {:type => "text_box", :name => "location_code",
                                           :is_required => "true", :scan_only => "false", :scan_field => true,
                                           :submit_form => true}

    screen_attributes = {:auto_submit => "false", :content_header_caption => "select location"}
    buttons = {"B3Label" => "Clear", "B2Label" => "Cancel", "B1Submit" => "submit_selected_location", "B1Label" => "Submit", "B1Enable" => "true", "B2Enable" => "false", "B3Enable" => "false"}
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def submit_selected_location
    @parent.location_code = self.pdt_screen_def.get_control_value("location_code").strip

    location = Location.find_by_location_code(@parent.location_code)
    if !location
      result_screen = PDTTransaction.build_msg_screen_definition("not a valid location", nil, nil, nil)
      return result_screen
    end

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
      return "location does not belong to selected parent location"
    end

     if @parent.spaces_left && @parent.spaces_left.to_i <= 0
      return  "location does not have enough space"
    end

    return nil

  end

end
