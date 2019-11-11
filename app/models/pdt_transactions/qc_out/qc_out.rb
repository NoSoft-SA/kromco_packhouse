class QcOut < PDTTransaction

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'carton_num',:is_required=>'true',:scan_field => true, :submit_form => true}

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"scan carton"}
    buttons = {"B3Label"=>"" ,"B2Label"=>"","B1Submit"=>"qc_out_submit","B1Label"=>"submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def qc_out
    build_default_screen
  end

  def qc_out_submit
    if (error=validate_inputs?) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,error)
      return result_screen
    else
      carton = self.scratch_pad["carton"]
      carton.pallet.transaction do
       carton.pallet.qc_status_code = "INSPECTING"
       carton.qc_status_code = "INSPECTING"
       carton.is_inspection_carton = true
       carton.qc_datetime_out = Time.now
       carton.pallet.update
       carton.update
     end
      self.set_transaction_complete_flag
      result = ["QC OUT SUCCESSFUL"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,result)
      return result_screen
    end
  end
  
   def validate_inputs?
    carton_num = self.pdt_screen_def.get_input_control_value("carton_num").to_i
    carton = Carton.find_by_carton_number(carton_num)
    self.set_temp_record("carton", carton)

   if !carton
     error = ["INVALID.  REASON: CTN 1: " + carton_num.to_s + " NOT FOUND"]
     return error
   end

   if !carton.pallet
     error = ["INVALID.  REASON: NO PALLET FOR CARTON 1: " + carton_num.to_s]
     return error
   end

   pallet = carton.pallet
   if pallet.qc_status_code && pallet.qc_status_code.upcase == "INSPECTING"
     error = ["INVALID.  REASON: PALLET CTN ALREADY TO PPECB"]
     return error
   end

   if pallet.qc_status_code && pallet.qc_status_code.upcase == "INSPECTED"
     error = ["INVALID.  REASON: PALLET INSPECTED ALREADY"]
     return error
   end

   return nil
  end
end
