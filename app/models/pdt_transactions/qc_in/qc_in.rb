class QcIn < PDTTransaction
  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'carton_num1',:is_required=>'true',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'carton_num2',:is_required=>'true',:scan_field => true}

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"scan cartons"}
    buttons = {"B3Label"=>"" ,"B2Label"=>"","B1Submit"=>"qc_in_submit","B1Label"=>"submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def qc_in
    build_default_screen
  end

  def validate_inputs?
   carton_num = self.pdt_screen_def.get_input_control_value("carton_num1").to_i
   carton2_num = self.pdt_screen_def.get_input_control_value("carton_num2").to_i.to_i
   #inspection_carton = nil
   #--------------------
   #various validations
   #--------------------
   carton1 = Carton.find_by_carton_number(carton_num)
   if !carton1
     error = ["INVALID.  REASON: CTN 1:" + carton_num.to_s + "NOT FOUND"]
     return error
   end

   carton2 = Carton.find_by_carton_number(carton2_num)
   if !carton2
     error = ["INVALID.  REASON: CTN 2:" + carton2_num.to_s + "NOT FOUND"]
     return error
   end

   if !carton1.pallet
     error = ["INVALID.  REASON: NO PALLET FOR CARTON 1:" + carton_num.to_s]
     return error
   end

    if !carton2.pallet
      error = ["INVALID.  REASON: NO PALLET FOR CARTON 2:" + carton2_num.to_s]
      return error
    end

   if !carton1.is_inspection_carton && !carton2.is_inspection_carton
      error = ["INVALID.  REASON: NEITHER CARTON IS AN INSPECTION CARTON"]
      return error
   else
    if carton1.is_inspection_carton
     inspection_carton = carton1
    else
     inspection_carton = carton2
    end
   end
   
   self.set_temp_record("inspection_carton", inspection_carton)
   if carton1.pallet.id != carton2.pallet.id
     error = ["INVALID.  REASON: 2 CARTONS BELONG TO DIFFERENT PALLETS"]
     return error
   end    
   return nil
  end

  def qc_in_submit    
    if (error=validate_inputs?) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,error)
      return result_screen
    else
      inspection_carton = self.scratch_pad["inspection_carton"]

      inspection_carton.transaction do
      inspection_carton.qc_datetime_in = Time.now
      if !inspection_carton.qc_status_code||inspection_carton.qc_status_code.upcase == "INSPECTING"
         inspection_carton.qc_status_code =nil
         inspection_carton.is_inspection_carton = false
         inspection_carton.pallet.qc_status_code = "UNINSPECTED"
         inspection_carton.update
         inspection_carton.pallet.update
       end
      end
      self.set_transaction_complete_flag
      result = ["QC IN SUCCESSFUL","PUT CTN: " + inspection_carton.carton_number.to_s + "BACK ON PALLET:" + inspection_carton.pallet.pallet_number.to_s]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,result)
      return result_screen
    end
  end
  
end
