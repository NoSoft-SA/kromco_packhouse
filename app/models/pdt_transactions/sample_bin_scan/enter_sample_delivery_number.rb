class EnterSampleDeliveryNumber < PDTTransactionState
  
 def initialize(parent)
   @parent = parent
   @current_bin_id = nil.to_s
 end 
   
 #----------------------------------------------
 # builds the default screen for this state
 #----------------------------------------------
 def build_default_screen
   field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_box",:name=>"delivery_number",:label=>"delivery number",:is_required=>"true",:scan_field => true, :submit_form => true}

   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"enter delivery number"}
   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"enter_sample_delivery_number_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
   plugins = Array.new
   plugins[plugins.length] = {:class_name=>'LabelPlugin',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
   #plugins[plugins.length] = {:class_name=>'Test3',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>''}
   screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

 end
 
 #----------------------------------------------
 # Client developer must implement this method
 # to define this state.If not defined here,it
 # needs to be defined in the parent transaction
 #----------------------------------------------
 def enter_sample_delivery_number
    return build_default_screen
 end

 def enter_sample_delivery_number_submit
  #current_delivery_number = self.pdt_screen_def.controls[0]["value"]
  current_delivery_number = @pdt_screen_def.get_input_control_value("delivery_number")

  self.parent.current_delivery_number = current_delivery_number

  #-------------------------------------------------------
  # transitioning  to another state.
  #------------------------------------------------------
  next_state = ScanSampleFullBin.new(self.parent)
#  puts "------------ Siyabangena 101 ---------" #Test
#  #Ca't I move these 2lines to transit_to_process???
#  require "app/models/pdt_transactions/rmt_sample_receipt/sample_transfer_pallet.rb"#Test
#  require "app/models/pdt_transactions/rmt_sample_receipt/rmt_sample_receipt.rb"#Test
#  self.parent = self.parent.transit_to_process("RmtSampleReceipt")#Test
#  next_state = SampleTransferPallet.new(self.parent) #Test - Incorrect State
#  puts "------------ Siyabangena 202 ---------"#Test

  result_screen_def = next_state.build_default_screen.to_s
  current_screen_def = PdtScreenDefinition.new(result_screen_def,nil,PdtScreenDefinition.const_get("ENTERDATA"),self.pdt_screen_def.user,self.pdt_screen_def.ip)
#  current_screen_def = PdtScreenDefinition.new(result_screen_def,"2.1.2",1,self.pdt_screen_def.user,self.pdt_screen_def.ip)#Test
#  self.parent.pdt_screen_def = current_screen_def#Test
  next_state.pdt_screen_def = current_screen_def
  self.parent.set_active_state(next_state)
  return result_screen_def

 end
 
  def permission?()
   # "ppecb_admin"
  end
  
end
