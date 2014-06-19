class MoveUnlabeledCartons < PalletSequenceNavigator

  def build_default_screen
    if(@main_error_screen)
      return @main_error_screen
    end
    parent_sequence_screen = build_sequence_screen
    temp = PdtScreenDefinition.new(parent_sequence_screen,nil,PdtScreenDefinition.const_get("ENTERDATA"),self.parent.pdt_screen_def.user,self.parent.pdt_screen_def.ip)
    temp.buttons["B3Enable"] = "true"
    temp.buttons["B3Label"] = "move"
    temp.buttons["B3Submit"] = "move_sequence_cartons"
    temp.screen_attributes["content_header_caption"] = "move sequence cartons"
#    temp.screen_attributes["current_menu_item"] = "1.7.1.3"
    temp.controls[temp.controls.length()] = {:type=>"static_text",:name=>"qty_remaining",:value=>self.parent.qty_cartons_remaining.to_s}
    temp.controls[temp.controls.length()] = {:type=>"text_box",:name=>"qty_to_move"}

    result_screen = temp.get_output_xml()
  end

  def validate_input
    qty_to_move = self.parent.pdt_screen_def.get_input_control_value("qty_to_move").to_i

    if qty_to_move > self.current_sequence[:carton_count].to_i
      return ["qty_to_move cannot be more that carton_count"]
    end

    if self.parent.pdt_screen_def.get_input_control_value("qty_to_move").to_i > self.parent.qty_cartons_remaining.to_i
      return ["qty_to_move more than qty_remaining"]
    end

    if (self.current_sequence[:carton_count].to_i - (self.current_sequence[:qty_moved].to_i + qty_to_move)) < 0
      return ["qty_to_move cannot be more than (carton_count attribute - (cartons_moved() attribute + submitted qty_to_move)) of current sequence"]
    end

    return nil
  end

  #______________________
  # 3. AMENDMENT
  #______________________
  def can_redo
    false
  end
  #______________________

  def move_sequence_cartons
    if (error = validate_input) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,error)
      return result_screen
    else
      if(self.current_sequence[:qty_moved] == nil)
        self.current_sequence[:qty_moved] =  self.parent.pdt_screen_def.get_input_control_value("qty_to_move").to_i#-----[[[ NOT IN SPEC ]]] ----Correct??
        self.current_sequence[:carton_count] = self.current_sequence[:carton_count].to_i - self.parent.pdt_screen_def.get_input_control_value("qty_to_move").to_i
      else
        self.current_sequence[:qty_moved] = self.current_sequence[:qty_moved] + self.parent.pdt_screen_def.get_input_control_value("qty_to_move").to_i#-----[[[ NOT IN SPEC ]]] ----Correct??
      end
    
      oustanding_cartons = self.parent.qty_cartons_remaining

      if(self.parent.qty_moved < oustanding_cartons)
        self.move_unlabeled_cartons
      else
        self.parent.move_trans()
        self.parent.set_transaction_complete_flag
        self.parent.build_completed_screen()
      end
    end
  end

  def move_unlabeled_cartons #Transit to EnterUnlabeledPalletNumber state
    next_state = EnterUnlabeledPalletNumber.new(self.parent)
    self.parent.set_active_state(next_state)
    return next_state.build_default_screen
  end
  
  def move_labeled_cartons
    next_state = MoveLabeledCartons.new(self.parent)
    self.parent.set_active_state(next_state)
    return next_state.build_default_screen
  end

end