class ScanSampleFullBin< PDTTransactionState
  attr_accessor :current_bin_id
 
 def initialize(parent)
  @parent = parent
  @current_bin_id = nil.to_s
 end
  
 #----------------------------------------------
 # builds the default screen for this state
 #----------------------------------------------  
 def build_default_screen
 
   #---------------------------------------------------------
   # this step will be reached after the user has submitted 
   # the delivery_number, after that the transaction's states 
   # cannot be undone and the transaction cannot be cancelled
   #---------------------------------------------------------
   #self.parent.set_cannot_cancel    
   current_delivery_number = self.parent.current_delivery_number 
 
   #-------------------------------------------------------------------------------
   # Specifying the contents of the default screen and passing them as settings
   # to the  PdtScreenDefinition's gen_screen_xml() method which will then generate
   # screen definition to be displayed in the pdt.
   #-------------------------------------------------------------------------------
   outputs = ["Delivery : " + current_delivery_number+ "(" + self.parent.required_bins.to_s + "bin scans required)",
              "current bin : " + self.current_bin_id.to_s,
              "full bins scanned : " + self.parent.number_of_full_bins_scanned.to_s,
              "half bins scanned : " + self.parent.number_of_half_bins_scanned.to_s ,nil,nil,
              "Scan full bin:"]

   field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[0]}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[1]}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[2]}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[3]}
      field_configs[field_configs.length] = {:type=>"text_box",:name=>"bin_id",:is_required=>"true",:value=>""}      

   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"Scan full bin"}
   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"Scan_sample_full_bin_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
   plugins = nil
   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

 end
  
 def Scan_sample_full_bin
    return build_default_screen 
 end

 def Scan_sample_full_bin_submit

  #----------------------------------------------------------------------------------------
  # sets the current_bin_id to the value that the user has just submitted
  #----------------------------------------------------------------------------------------
  self.current_bin_id = self.pdt_screen_def.controls[self.pdt_screen_def.controls.length-1]["value"]

  self.parent.number_of_full_bins_scanned = self.parent.number_of_full_bins_scanned + 1
  self.parent.total_bins_scanned = self.parent.total_bins_scanned + 1

  #------------------------------------------------------------------------------------
  # here I'm using build_default_screen() because it so happens that in this state,the
  # result screen for a request and a submition are similar.
  #------------------------------------------------------------------------------------
  result_screen_def = build_default_screen()

  #---------------------------------------------------------------------------------------
  # condition to end transaction.Once this is met, I set is_transaction_complete attribute
  # of the current transaction to false,which will terminate it!
  #---------------------------------------------------------------------------------------
  if self.parent.total_bins_scanned == (self.parent.required_bins)
    current_delivery_number = self.parent.current_delivery_number
    outputs = ["Finished bin scanning for delivery = " + current_delivery_number + "(" + self.parent.required_bins.to_s + "bin scans required)",
               "current bin = " + self.current_bin_id,
               "full bins scanned : " + self.parent.number_of_full_bins_scanned.to_s ,
               "half bins scanned : " + self.parent.number_of_half_bins_scanned.to_s]

    field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[0]}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[1]}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[2]}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>outputs[3]}

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"Scanning Complete"}
    buttons = nil#{"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    #COMPLETING TRANSACTION
    self.parent.set_active_state(nil)
    self.parent.set_transaction_complete_flag
  end

  return result_screen_def  
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
   next_state.current_bin_id = self.current_bin_id.to_s
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
  
  def Complete_sample_delivery
     next_state = CompleteSampleDelivery.new(self.parent)
     next_state.previous_state = self
     next_state.current_bin_id = self.current_bin_id.to_s
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