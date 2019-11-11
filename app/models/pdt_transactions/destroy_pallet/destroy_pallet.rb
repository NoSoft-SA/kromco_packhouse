class DestroyPallet < PDTTransaction

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_pallet",:is_required=>"true",:scan_field => true, :submit_form => true}

    buttons = {"B1Label"=>"submit","B1Enable"=>"true","B1Submit"=>"destroy_pallet_submit","B2Label"=>"","B2Enable"=>"false","B3Submit"=>"","B3Enable"=>"false","B3Submit"=>""}
    screen_attributes = {:content_header_caption=>"destroy pallet",:auto_submit=>"false"}
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,nil)
  end

  def destroy_pallet
    build_default_screen
  end

  def validate_input
    scanned_pallet = PDTFunctions.extract_pallet_num(self.pdt_screen_def.get_input_control_value("scan_pallet"))
    #if scanned_pallet.kind_of?(Fixnum) || scanned_pallet.kind_of?(Bignum)
    if !scanned_pallet.upcase.include?("INVALID")
      pallet = Pallet.find_by_pallet_number(scanned_pallet)
      self.set_temp_record("pallet", pallet)
      
      if(pallet == nil)        
        return ["pallet was not found"]
      end
      
      if(pallet.carton_quantity_actual == 0)
        return nil
      else
        self.set_transaction_complete_flag
        return ["pallet has " + pallet.carton_quantity_actual.to_s + " cartons","It cannot be destroyed"]
      end
    else
      return [scanned_pallet]
    end
  end

  def destroy_pallet_submit
    if (error = validate_input) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,error)
      return result_screen
    else
      destroy_pallet_trans
    end
  end


  def destroy_pallet_trans

      ActiveRecord::Base.transaction do

        pallet = self.get_temp_record("pallet")

        stock_item = StockItem.find_by_inventory_reference(pallet.pallet_number)
        raise "Pallet: " + pallet.pallet_number + " does not exist in inventory " if !stock_item
        location_code =  stock_item.location_code

        Inventory.remove_stock(nil, "PALLET", "DESTROY_PALLET",nil,location_code, [pallet.pallet_number])

        pallet.update_attribute(:exit_ref,"pallet_destroyed")
        pallet_histroy = PalletHistory.new
        pallet.export_attributes(pallet_histroy)
        pallet_histroy.crud_user_name = self.pdt_screen_def.user
        pallet_histroy.crud_date_time = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
        pallet_histroy.crud_reason = "";
        pallet_histroy.crud_type = "destroy";
        pallet_histroy.create
        self.set_transaction_complete_flag
        #result = ["pallet.carton_quantity_actual = " + pallet.carton_quantity_actual.to_s + "pallet_num = " + pallet.pallet_number.to_s,"operatore = " + self.pdt_screen_def.user.to_s]
        result = ["pallet:" + pallet.pallet_number.to_s + " has been deleted successfully"]
        result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,result)
         return result_screen
      end

  end
end
