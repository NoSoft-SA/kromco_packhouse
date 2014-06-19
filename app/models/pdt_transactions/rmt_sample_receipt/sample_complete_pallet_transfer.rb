class SampleCompletePalletTransfer < PDTTransactionState
 
  def initialize(parent)
   @parent = parent 
  end
  
  def build_default_screen
   msg = ["You haven't transfered the maximum number of pallets","Are you sure you want to complete this transfer transaction?"]
   #-----------------------------------------------------
   # build_choice_screen() is a PDTTransaction method
   # i.e. is accessible to all the classes that inherit
   # from it
   #-----------------------------------------------------
   result_screen_def = self.parent.build_choice_screen(msg)               
   return result_screen_def   
  end
    
  def sample_complete_pallet_transfer
    return build_default_screen
  end

  def sample_complete_pallet_transfer_submit

  if self.pdt_screen_def.mode.to_s == 4.to_s
   if @parent.current_pallet_number != nil
    lcd3 = "Last pallet transfered : " + @parent.current_pallet_number
    lcd4 = "                        [ from location = " + @parent.current_pallet_previous_location + " ]"
   else
    lcd3 = nil
    lcd4 = nil
   end
    outputs = ["Destination : " + @parent.location_code,
              "Pallets transfered : " + @parent.num_transfered_pallets.to_s + "  (of " + @parent.total_pallets.to_s + ")",
              lcd3.to_s,
              lcd4.to_s,nil,nil,nil]
    result_screen_def = PdtScreenDefinition.gen_screen_xml(inputs=nil,outputs,buttons=nil)
    #COMPLETING TRANSACTION
    self.parent.set_active_state(nil)
    self.parent.is_transaction_complete = true
    else
     next_state = SampleScanPallet.new(self.parent)
     result_screen_def = next_state.build_default_screen

     current_screen_def = PdtScreenDefinition.new(result_screen_def,nil,PdtScreenDefinition.const_get("ENTERDATA"),result_screen_def,self.pdt_screen_def.user,self.pdt_screen_def.ip)

     next_state.pdt_screen_def = current_screen_def
     self.parent.set_active_state(next_state)
    end

    return result_screen_def
  end
  
  def permission?
    "admin"
  end
  
end