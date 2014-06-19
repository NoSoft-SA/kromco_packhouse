class ConfirmPrintTripsheet < PDTTransactionState
 
  def initialize(parent)
    @parent = parent
  end
  
  def build_default_screen
     if @parent.qty_pallets_scanned == @parent.qty_pallets_required
       label =  'pallets scanned = qty required'
     else
       label = 'pallets scanned < qty required'
     end
     prompt_msg_array = [label,"print tripsheet?",nil,nil,nil,nil,nil]

     screen_attributes = {:auto_submit=>"false",:content_header_caption=>"print tripsheet?"}
     #buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"load_vehicle_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
     plugins = nil
     result_screen_def = @parent.build_choice_screen(prompt_msg_array,screen_attributes,plugins)

     return result_screen_def
  end

  def yes()
    #----------------------------------------
     if(@parent.load_vehicle_completed?)
        return @parent.build_complete_screen
     end
     #----------------------------------------
     
     @parent.complete_trans(false)
     vehicle_job_no =  @parent.get_temp_record(:vehicle_job_no) #@parent.vehicle_job_no
     require "app/models/pdt_transactions/print_tripsheet/print_tripsheet.rb"
     self.parent = self.parent.transit_to_process("PrintTripsheet")
     self.parent.vehicle_job_no = vehicle_job_no
     result_screen = self.parent.build_default_screen

#     self.parent.pdt_method = PDTTransaction.create_pdt_method("print_tripsheet")
     self.parent.set_active_state(nil)
     return result_screen
  end

  def no()
    #----------------------------------------
    if(@parent.load_vehicle_completed?)
        return @parent.build_complete_screen
    end
    #----------------------------------------

    if @parent.qty_pallets_scanned.to_i == @parent.qty_pallets_required.to_i
       msg2 = "vehicle loaded with " + @parent.qty_pallets_scanned.to_s + " pallets."
      @parent.complete_trans(true)
      field_configs = Array.new
       msg1 = "created tripsheet: " + @parent.get_temp_record(:vehicle_job_no) #@parent.vehicle_job_no

      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>msg1.to_s}
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output2",:value=>msg2.to_s}

      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"vehicle loaded"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"load_vehicle_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    else
      next_state = ScanPallet.new(@parent)
      result_screen = next_state.build_default_screen
      self.set_active_state(next_state)
      return result_screen
    end
    
  end

end
