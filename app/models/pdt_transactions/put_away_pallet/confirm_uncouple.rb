class ConfirmUncouple < PDTTransactionState
  
  def initialize(parent)
    @parent = parent
  end

  def build_default_screen()
    pallet = Pallet.find_by_pallet_number(@parent.pallet_number)
    label = "PALLET ON LOAD " + pallet.load_detail_id.to_s + " : UNCOUPLE PALLET FROM LOAD?"
    prompt_msg_array = [label,nil,nil,nil,nil,nil,nil]
    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"uncouple pallet"}
    plugins = nil
    result_screen_def = @parent.build_choice_screen(prompt_msg_array,screen_attributes,plugins)

    return result_screen_def
  end

  def yes()
#    @parent.putaway_trans(true)
    self.parent.uncouple_load = true

    next_state = ScanPutawayLocation.new(self.parent)
    result_screen = next_state.build_default_screen
    self.parent.set_active_state(next_state)
    return result_screen
  end

  def no()
#    @parent.set_transaction_complete_flag
#    field_configs = Array.new
#    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"PUTAWAY ABORTED!"}
#    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"putaway aborted"}
#    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"uncouple_pallet_no","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
#    return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    self.parent.set_repeat_process_flag
  end

end
