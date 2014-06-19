class CompleteSampleDelivery < PDTTransactionState
 attr_accessor :current_bin_id, :previous_state
 
 def initialize(parent)
  @parent = parent
  @current_bin_id = nil.to_s
 end
 
 #----------------------------------------------
 # builds the default screen for this state
 #----------------------------------------------   
 def build_default_screen
  msg = ["You have not scanned all the required bins","Are you sure you want to complete the delivery transaction?"]
  screen_attributes = {:auto_submit=>"false",:content_header_caption=>""}
  result_screen_def = self.parent.build_choice_screen(msg,screen_attributes,nil)
  return result_screen_def   
 end
 
 def Complete_sample_delivery
   return build_default_screen
 end

 #Any button other button submission than yes/no will be executed here
 def Complete_sample_delivery_submit
 end

 def yes
      outputs = ["Finished bin scanning for delivery = " + self.parent.current_delivery_number + " (" + self.parent.required_bins.to_s + "bin scans required)",
               "current bin : " + self.current_bin_id,
               "full bins scanned : " + self.parent.number_of_full_bins_scanned.to_s ,
               "half bins scanned : " + self.parent.number_of_half_bins_scanned.to_s]

    field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[0]}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[1]}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[2]}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[3]}

   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"Scan full bin"}
   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
   plugins = nil
   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    #COMPLETING TRANSACTION
    self.parent.set_active_state(nil)
    self.parent.set_transaction_complete_flag

    return result_screen_def
 end

 def no
   if self.previous_state.class.name == "ScanSampleFullBin"
     Scan_sample_full_bin()
   else
     Scan_sample_half_bin()
   end
 end
  
 #----------------------------------------------------------------
 # A state can be requestes to transition to others in 2 ways
 # 1. through a menu item selection
 # 2. if the all the tasks that are needed to complete this state
 #    have been completed,the client developer will just transtion
 # 
 # To allow a state to be able to transition to other states by 
 # menu selction,the client developer must implement all the
 # methods to handle all the possible menu item selection requests
 # from the user].
 #----------------------------------------------------------------
 def Scan_sample_half_bin
  next_state = ScanSampleHalfBin.new(self.parent)
  next_state.current_bin_id = self.current_bin_id
  result_screen_def = next_state.build_default_screen.to_s
  
  #-----------------------------------------------------------------------
  # sets the current pdt_screen_def,which is used in next step the process
  # to determine the current program_fuction(menu_item) to invoke in the 
  # next cycle
  #-----------------------------------------------------------------------  
  current_screen_def = PdtScreenDefinition.new(result_screen_def,nil,PdtScreenDefinition.const_get("ENTERDATA"),self.pdt_screen_def.user,self.pdt_screen_def.ip)
          
  next_state.pdt_screen_def = current_screen_def
  self.parent.set_active_state(next_state)                    
   return result_screen_def
 end
  
 def Scan_sample_full_bin
  next_state = ScanSampleFullBin.new(self.parent)
  next_state.current_bin_id = self.current_bin_id
  result_screen_def = next_state.build_default_screen.to_s
  
  #-----------------------------------------------------------------------
  # sets the current pdt_screen_def,which is used in next step the process
  # to determine the current program_fuction(menu_item) to invoke in the 
  # next cycle
  #-----------------------------------------------------------------------  
  current_screen_def = PdtScreenDefinition.new(result_screen_def,nil,PdtScreenDefinition.const_get("ENTERDATA"),self.pdt_screen_def.user,self.pdt_screen_def.ip)
       
  next_state.pdt_screen_def = current_screen_def
  self.parent.set_active_state(next_state)
                      
  return result_screen_def
 end
  
end