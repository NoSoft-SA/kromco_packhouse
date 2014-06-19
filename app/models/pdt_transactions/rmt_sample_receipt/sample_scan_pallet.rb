class SampleScanPallet < PDTTransactionState
 
  def initialize(parent)
   @parent = parent 
  end
  
  def build_default_screen
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
              lcd4.to_s,nil,nil,"scan pallet"]
   inputs = {:previous_location_code=>"",:pallet_number=>""}
   result_screen_def = PdtScreenDefinition.gen_screen_xml(inputs,outputs,buttons=nil)

#    field_configs = Array.new
#      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"*************************"}
#      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"The Transitioning to "}
#      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"another transaction was done successfully"}
#      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"*************************"}
#
#   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transit to process test"}
#   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
#   plugins = nil
#   screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end
  
  def sample_scan_pallet
   if is_screen_request == true
    return build_default_screen
   end
   
    self.parent.current_pallet_previous_location = self.pdt_screen_def.inputs["Input2"][:value].to_s
    self.parent.current_pallet_number = self.pdt_screen_def.inputs["Input1"][:value].to_s
    @parent.num_transfered_pallets += 1

    
   if @parent.num_transfered_pallets == @parent.total_pallets
    lcd3 = "Last pallet transfered : " + @parent.current_pallet_number
    lcd4 = "                        [ from location = " + @parent.current_pallet_previous_location + " ]"

    outputs = ["Destination : " + @parent.location_code,
             "Pallets transfered : " + @parent.num_transfered_pallets.to_s + "  (of " + @parent.total_pallets.to_s + ")",
             lcd3.to_s,
             lcd4.to_s,nil,nil,nil] 
    
    result_screen_def = PdtScreenDefinition.gen_screen_xml(inputs=nil,outputs,buttons=nil)
    #COMPLETING TRANSACTION
    self.parent.set_active_state(nil)     
    self.parent.is_transaction_complete = true            
    return result_screen_def
   end
   
   return build_default_screen
  end
  
  def sample_complete_pallet_transfer
     next_state = SampleCompletePalletTransfer.new(self.parent)
     result_screen_def = next_state.build_default_screen.to_s
   
     #-----------------------------------------------------------------------
     # sets the current pdt_screen_def,which is used in next step of the process
     # to determine the current program_fuction(menu_item) to invoke in the 
     # next cycle
     #-----------------------------------------------------------------------
     current_screen_def = PdtScreenDefinition.new(result_screen_def,nil,PdtScreenDefinition.const_get("ENTERDATA"),result_screen_def,self.pdt_screen_def.user,self.pdt_screen_def.ip)
     next_state.pdt_screen_def = current_screen_def
     self.parent.set_active_state(next_state)

     return result_screen_def
  end
  
end