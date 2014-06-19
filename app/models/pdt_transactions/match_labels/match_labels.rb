class MatchLabels < PDTTransaction

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'carton',:is_required=>'true'}
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'pallet',:is_required=>'true'}

    buttons = {"B1Label"=>"submit","B1Enable"=>"true","B1Submit"=>"match_labels_submit","B2Label"=>"","B2Enable"=>"false","B3Submit"=>"","B3Enable"=>"false","B3Submit"=>""}
    screen_attributes = {:content_header_caption=>"match carton and pallet label",:auto_submit=>"false"}
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,nil)
  end

  def match_labels
    build_default_screen
  end

  def validate_input
    pallet_number = PDTFunctions.extract_pallet_num(self.pdt_screen_def.get_input_control_value("pallet"))
#    return pallet_number
    #if pallet_number.kind_of?(Fixnum) || pallet_number.kind_of?(Bignum)
    if !pallet_number.upcase.include?("INVALID")
      set_temp_record("pallet", pallet_number)
      return nil
    else
      return [pallet_number]
    end
    
  end

  def match_labels_submit
    if(error = validate_input) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,error)
      #return result_screen
    else
      pallet_rec = Pallet.find_by_pallet_number(self.get_temp_record("pallet"))
      #carton_rec = Carton.find_by_carton_number(self.pdt_screen_def.get_input_control_value("carton").to_i)
       carton_number = PDTFunctions.extract_carton_num(self.pdt_screen_def.get_control_value("carton"))
       carton_rec = Carton.find_by_carton_number(carton_number)

      if(carton_rec == nil)
        result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,["carton:" + self.pdt_screen_def.get_input_control_value("carton"),"was not found"])
        #return result_screen
      elsif(pallet_rec == nil)
        result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,["pallet" + self.pdt_screen_def.get_input_control_value("pallet"),"was not found"])
        #return result_screen
      else
        if(carton_rec.pallet_number == pallet_rec.pallet_number)
          result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,["CARTON BELONGS ON PALLET"])
          #return result_screen
        else
          result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,["CARTON DOES NOT BELONGS ON PALLET"])
          #return result_screen
        end
      end
    end

    self.set_transaction_complete_flag
    return result_screen
  end
end