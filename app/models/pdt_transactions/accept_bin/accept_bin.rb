class  AcceptBin < PDTTransaction
  attr_accessor :scanned_bins,:location_code,:bin_number,:delivery_number,:transaction_type,:delivery_id, :location_type_code

  def initialize
    @scanned_bins = Array.new
    @location_code = location_code
    @transaction_type = ""
    @delivery_number  = ""
  end



  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"location_barcode",:is_required=>"true",:scan_field => true, :submit_form => true}

    screen_attributes = {:auto_submit=>"true",:auto_submit_to=>"location_entered",:content_header_caption=>"Scan to Location"}
    buttons = {"B3Label"=>"" ,"B2Label"=>"","B1Submit"=>"location_entered","B1Label"=>"submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
     return result_screen_def
  end

  def scan_location
    build_default_screen
  end

  def valid_location?
    location_entered = self.pdt_screen_def.get_control_value("location_barcode")

    location = Location.find_by_sql("select * from locations where location_barcode = '#{location_entered}' order by id desc ")[0]

  if location == nil
      error = ["Invalid location  bar code !"]
      return error
  end

  location_status =  Location.check_location_status(location.location_barcode)
  if  location_status  != nil
     if location_status == "SEALED"
      error = ["Bins cannot be moved to location '#{location_entered}', status is: SEALED "]
     elsif location_status == "GAS"
       error = ["Bins cannot be moved to location '#{location_entered}', status is: GAS "]
    end
       return error
  end

    @location_type_code = location.location_type_code


    @location_code = location.location_code

   return nil
  end


  def location_entered
    if (error = valid_location?) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(error,nil,nil,nil)
      return result_screen

    else
    next_state = ScanBinToLocation.new(self)
     self.set_active_state(next_state)
     return next_state.build_default_screen
    end
  end

end
