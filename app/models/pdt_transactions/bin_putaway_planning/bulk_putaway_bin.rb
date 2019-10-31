class BulkPutawayBin < PDTTransactionState

  def initialize(parent)
    @parent = parent
  end

  def build_default_screen
    field_configs = Array.new

    field_configs[field_configs.length] = {:type=>"static_text", :name=>"coldroom", :value=>@parent.coldroom}
    # field_configs[field_configs.length] = {:type=>"static_text", :name=>"putaway_location", :value=>@parent.location_code}
    # field_configs[field_configs.length] = {:type=>"static_text", :name=>"qty_bins_to_putaway", :value=>@qty_bins}
    # field_configs[field_configs.length] = {:type=>"static_text", :name=>"bins_scanned", :value=>"#{@parent.scanned_bins.length().to_s}"}
    # field_configs[field_configs.length] = {:type=>"static_text", :name=>"space_left", :value=>"#{@positions_available.to_s}"}
    # field_configs[field_configs.length] = {:type=>"text_box",:name=>"bin_number",
    #                                        :is_required=>"true",:scan_only=>"false",:scan_field => true,
    #                                        :submit_form => true}

    screen_attributes = {:auto_submit=>"true", :auto_submit_to=>"bin_scanned_submit",:cache_screen => true}
    buttons = {"B3Label"=>"" ,"B2Label"=>"","B1Submit"=>"bin_scanned_submit","B1Label"=>"submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }

    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

end