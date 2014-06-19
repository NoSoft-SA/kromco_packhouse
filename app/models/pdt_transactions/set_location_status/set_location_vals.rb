class SetLocationVals < PDTTransactionState
  
  def initialize(parent)
    @parent = parent
  end

  def set_location_vals

  end

  def build_default_screen()
    location_or_facility_code = ""
    if @parent.location_code
      location_or_facility_code = @parent.location_code
    else
      location_or_facility_code = @parent.facility_code
    end
    date_from = "null"
    date_from = @parent.date_from.strftime("%Y-%b-%d") if @parent.date_from
    date_to = "null"
    date_to = @parent.date_to.strftime("%Y-%b-%d") if @parent.date_to
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"location_or_facility_code",:value=>location_or_facility_code}
    field_configs[field_configs.length] = {:type=>"check_box",:name=>"unavailable",:value=>@parent.unavailable}
    field_configs[field_configs.length] = {:type=>"date",:name=>"date_from",:label=>"unavailable_from",:value=>date_from}
    field_configs[field_configs.length] = {:type=>"date",:name=>"date_to",:label=>"unavailable_to",:value=>date_to}
    if @parent.facility_code
      field_configs[field_configs.length] = {:type=>"static_text",:name=>"warning",:value=>"NB: All locations inside facility will be affected."}
    end

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"set location vals"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"set_location_vals_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def set_location_vals_submit()
    @parent.unavailable = self.pdt_screen_def.get_control_value("unavailable")
    @parent.date_from = self.pdt_screen_def.get_control_value("date_from")
    @parent.date_to = self.pdt_screen_def.get_control_value("date_to")

    @parent.set_location_status_trans

    @parent.set_transaction_complete_flag
    #return "...."  # complete notification screen to confirm that trans is complete
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"transaction completed successifully!"}
    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transaction complete"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"load_vehicle_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

end
