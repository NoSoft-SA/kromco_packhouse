class BulkPutawayBin < PDTTransactionState

  def initialize(parent)
    @parent = parent
  end

  def build_bulk_putaway_screen

    field_configs = Array.new

    field_configs[field_configs.length] = {:type => "static_text", :name => "coldroom", :value => @parent.coldroom}
    field_configs[field_configs.length] = {:type => "static_text", :name => "putaway_location", :value => @parent.location_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "positions_available", :value => "#{@parent.positions_available.to_s}"}
    field_configs[field_configs.length] = {:type => "text_box", :name => "location_code_to",
                                           :is_required => "true", :scan_only => "false", :scan_field => true,
                                           :submit_form => true}

    screen_attributes = {:auto_submit => "true", :auto_submit_to => "scanned_location_submit", :cache_screen => true}
    buttons = {"B3Label" => "", "B2Label" => "", "B1Submit" => "scanned_location_submit", "B1Label" => "submit", "B1Enable" => "false", "B2Enable" => "false", "B3Enable" => "false"}


    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def scanned_location_submit
    @scanned_location = @parent.pdt_screen_def.get_control_value("location_code_to").strip

    @location_to = Location.find_by_location_code(@scanned_location)
    if !@location_to
      result_screen = PDTTransaction.build_msg_screen_definition("Not a valid location", nil, nil, nil)
      return result_screen
    end

    error = validate_scanned_location

    if error
      result_screen = PDTTransaction.build_msg_screen_definition(error, nil, nil, nil)
      return result_screen
    else
      do_bulk_putaway
      complete_bin_putaway_plan
    end
  end

  def complete_bin_putaway_plan()
    @parent.set_transaction_complete_flag
    result = ["Location:#{@parent.location_code} Bin putaway plan created"]
    result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, 2, result)
    return result_screen

  end

  def validate_scanned_location

    if @scanned_location.to_s.upcase != @parent.location_code.to_s.upcase
      return "Scanned location different from putaway location."
    end
    #- validate that the scan location has enough space ,
    #  i.e. positions_available must be same or greater that the bin_putaway_plan.bins_to_putaway
    if (@location_to.location_maximum_units.to_i - @location_to.units_in_location.to_i) < @parent.scanned_bins.length
      return "Scanned location has less space than putaway plan."
    end

    return nil
  end

  def do_bulk_putaway
    @parent
    # - copy contents of bins_to_putaway to bins_putaway_completed
    # @parent.plan.bins_putaway_completed = @bin_putaway_plan.bins_to_putaway
    # @parent.plan.completed = true
    # @parent.plan.updated_at = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
    # @parent.plan.user_name = @parent.pdt_screen_def.user
    # @parent.plan.update
  end

end