class UnitTempCapture < PDTTransaction

  def build_default_screen


    temperature_device_type_codes = TemperatureDeviceType.find_by_sql("select distinct temperature_device_type_code from temperature_device_types").map{|t|t.temperature_device_type_code}
    temp_device_list_str =   temperature_device_type_codes.join(",")

    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"drop_down",:name=>'device_type',:list_field=>'temperature_device_type_code',:list=> temp_device_list_str,:is_required=>'true'}
    field_configs[field_configs.length] = {:type=>"drop_down",:name=>'unit_type',:list_field=>'unit_type_code',:get_list=>'get_unit_type_list',:is_required=>'true'}
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'temperature_device_code',:is_required=>'true',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'unit_id',:is_required=>'true', :scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'temperature',:is_required=>'true'}
    
    buttons = {:B1Label=>"Submit",:B1Enable=>"true",:B1Submit=>"unit_temp_capture_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"unit temperature capture",:auto_submit=>"false"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

  end
  
  def unit_temp_capture
    build_default_screen
  end

  def unit_temp_capture_submit
    if (error = validate_input) != nil
      result_screen = PDTTransaction.build_msg_screen_definition("ERROR = " + error,nil,nil,nil)
      return result_screen
    else
      unit_temp_capture_trans
    end
  end

  def unit_temp_capture_trans
    #begin
      unit_temperature = UnitTemperature.new
      unit_temperature.reading_date_time = Time.now
      unit_temperature.temperature_celsius = Float(self.pdt_screen_def.get_input_control_value("temperature"))
      unit_temperature.unit_type_code = self.pdt_screen_def.get_input_control_value("unit_type")
      unit_temperature.unit_type_id = UnitType.find_by_unit_type_code(self.pdt_screen_def.get_input_control_value("unit_type")).id
      unit_temperature.unit_number = self.pdt_screen_def.get_input_control_value("unit_id")
      unit_temperature.temperature_device_type_code = self.pdt_screen_def.get_input_control_value("device_type")
      unit_temperature.temperature_device_type_id = TemperatureDeviceType.find_by_temperature_device_type_code(self.pdt_screen_def.get_input_control_value("device_type")).id
      unit_temperature.user_name = self.pdt_screen_def.user
      unit_temperature.temperature_device_code = self.pdt_screen_def.get_input_control_value("temperature_device_code")
      unit_temperature.save!
      self.set_transaction_complete_flag
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,[self.pdt_screen_def.get_input_control_value("unit_type") + " temperature recorded","successfully"])
      return result_screen
    #rescue
#      puts "Diagnosis = " + $!.to_s
#      puts "BLEW UP = " + $!.backtrace.join("\n").to_s
      #result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,[self.pdt_screen_def.get_input_control_value("unit_type") + " temperature","could NOT be recorded","successfully"])
     # return result_screen
   # end
  end
  
  def validate_input
    unit_type = self.pdt_screen_def.get_input_control_value("unit_type")
    unit_id = self.pdt_screen_def.get_input_control_value("unit_id")
    temp = self.pdt_screen_def.get_input_control_value("temperature").to_i
    
    if(unit_type == "pallet")
      pallet_num = PDTFunctions.extract_pallet_num(unit_id)
#      if((pallet_num.kind_of?(Fixnum)) || (pallet_num.kind_of?(Bignum)))
#      else
      if pallet_num.upcase.include?("INVALID")
        return pallet_num
      end
      unit = Pallet.find_by_pallet_number(pallet_num)
    elsif(unit_type == "carton")
      unit = Carton.find_by_carton_number(unit_id.to_i)
      if(unit != nil && unit.pallet_number == nil)
        return "carton does not belong to any pallet"
      end
    elsif(unit_type == "bin")
      unit = Bin.find_by_bin_number(unit_id.to_s)
    elsif(unit_type == "rebin")
      unit = Bin.find_by_bin_number(unit_id.to_s)
    end

    if unit == nil
      return unit_type + " : " + unit_id + " could not be found"
    end

    if(temp > 60 || temp < -10)
      return "TEMP:" + temp.to_s + " is out of range"
    end

    return nil
  end
end
