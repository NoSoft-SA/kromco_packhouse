class SetLocationStatus < PDTTransaction

  attr_accessor :location_code, :facility_code, :unavailable, :date_from, :date_to

  def set_location_status
    if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
      build_default_screen
    else
      set_location_status_submit
    end
  end

  def build_default_screen()
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"location_or_facility_barcode",:is_required=>"true"}
    
     screen_attributes = {:auto_submit=>"false",:content_header_caption=>"load vehicle"}
     buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"set_location_status_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
     plugins = nil
     result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

     return result_screen_def
  end

  def set_location_status_submit()
    error_msg = validate_input
    if error_msg.to_s.strip == ""
      next_state = SetLocationVals.new(self)
      result_screen = next_state.build_default_screen
      self.set_active_state(next_state)
      return result_screen
    else
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>error_msg}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error message"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"set_location_status_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    end
  end

  def set_location_status_trans()
    ActiveRecord::Base.transaction do
      if self.location_code
        location = Location.find_by_location_code(self.location_code)
        location.unavailable = self.unavailable
        location.unavailable_from = self.date_from
        location.unavailable_to = self.date_to
        location.update
      else
        facility = Facility.find_by_facility_code(self.facility_code)
        facility.unavailable = self.unavailable
        facility.unavailable_from = self.date_from
        facility.unavailable_to = self.date_to
        facility.update
        locations = facility.locations
        for ltn in locations
          ltn.unavailable = self.unavailable
          ltn.unavailable_from = self.date_from
          ltn.unavailable_to = self.date_to
          ltn.update
        end
      end
    end
  end

  def validate_input()
    error_msg = ""
    location_facility_barcode = self.pdt_screen_def.get_control_value("location_or_facility_barcode")
    location = Location.find_by_location_barcode(location_facility_barcode)
    if location
      self.location_code = location.location_code
      self.unavailable = location.unavailable
      self.date_from = location.unavailable_from
      self.date_to = location.unavailable_to
    else
      facility = Facility.find_by_facility_barcode(location_facility_barcode)
      if facility
        self.facility_code = facility.facility_code
        self.unavailable = facility.unavailable
        self.date_from = facility.unavailable_from
        self.date_to = facility.unavailable_to
      else
        error_msg = "LOCATION NOT FOUND!"
      end
    end
    return error_msg
  end

end
