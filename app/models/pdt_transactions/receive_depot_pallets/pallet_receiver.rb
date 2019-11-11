# To change this template, choose Tools | Templates
# and open the template in the editor.

class PalletReceiver < PDTTransactionState
  
  def build_default_screen
    field_configs = Array.new
      field_configs[field_configs.length] = {:name=>'validated_pallet',:type=>'static_text',:label=>'validated pallets',:value=>self.parent.validated_pallets.to_s + " of " + self.parent.depot_pallets.length().to_s}
      field_configs[field_configs.length] = {:name=>'received_pallet',:type=>'text_box',:label=>'scan pallet',:is_required=>'true',:scan_field => true, :submit_form => true}

    buttons = {:B1Label=>"Submit",:B1Enable=>"true",:B1Submit=>"pallet_receiver_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"pallet receiver",:auto_submit=>"false"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end

  def pallet_receiver
    build_default_screen
  end

  

  def pallet_receiver_submit
    if (error = validate_input) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,error)
      return result_screen
    else
      pallet_number = self.parent.get_temp_record(:pallet_number)
      if self.parent.scanned_pallets.has_key?(pallet_number)
         if(self.parent.scanned_pallets[pallet_number] != nil)
           self.parent.set_active_state(self.parent.scanned_pallets[pallet_number])
           return self.parent.scanned_pallets[pallet_number].build_default_screen
         else
           #CREATE val
           self.parent.scanned_pallets[pallet_number] = SequenceValidator.new(self.parent, pallet_number)
           self.parent.set_active_state(self.parent.scanned_pallets[pallet_number])
           return self.parent.scanned_pallets[pallet_number].build_default_screen
         end
       else
         #CREATE key|val
           self.parent.scanned_pallets.store(pallet_number, SequenceValidator.new(self.parent, pallet_number))
           self.parent.set_active_state(self.parent.scanned_pallets[pallet_number])
           return self.parent.scanned_pallets[pallet_number].build_default_screen
       end
    end
  end


  def show_not_yet_validated_pallets
    return self.parent.show_not_yet_validated_pallets
  end

  def receive_depot_pallets
    build_default_screen
  end

  def show_validated_pallets
    return self.parent.show_validated_pallets
  end

  def validate_input

    scanned_pallet = self.parent.pdt_screen_def.get_input_control_value("received_pallet")
    pallet_number = PDTFunctions.extract_pallet_num(scanned_pallet)
    self.parent.set_temp_record(:pallet_number, pallet_number)
    if !pallet_number.upcase.include?("INVALID")
     stock_item = StockItem.find_by_inventory_reference(pallet_number)
     if stock_item != nil
       error = ["scanned pallet EXISTS in stock_items"]
       return error
     else
       if self.parent.depot_pallets.include?(pallet_number)
         return nil
       else
         error = ["scanned depot pallet = " + pallet_number.to_s,"does not belong to the scanned intake header = " + self.parent.intake_header_number.to_s]
         return error
       end
     end
    else
      error = [pallet_number]
      return error
    end
  end
end
