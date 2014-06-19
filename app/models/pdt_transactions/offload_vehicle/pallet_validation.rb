
class PalletValidation < PalletSequenceNavigator

  def validate_pallet
    build_default_screen
  end
 
  def validate_pallets
    #>>>>>>>>>
    unlock
    #>>>>>>>>>
    next_state = ValidatePallets.new(@parent)
    result_screen = next_state.build_default_screen
    @parent.set_active_state(next_state)
    return result_screen
  end
  
  def build_default_screen
    if(@main_error_screen)
      return @main_error_screen
    end

#    @parent.set_cannot_undo
    
    screen_definition = build_sequence_screen
    temp = PdtScreenDefinition.new(screen_definition,nil,PdtScreenDefinition.const_get("ENTERDATA"),nil,nil) #"1.2.2a"
    temp.controls[temp.controls.length()] = {:type=>"check_box",:name=>"valid",:label=>"valid?", :value=>@current_sequence[:validated]}
    temp.screen_attributes["content_header_caption"] = "validating sequence " + (@current_sequence_index + 1).to_s + " of " + @sequences.length.to_s
    temp.buttons["B3Enable"] = "true"
    temp.buttons["B3Label"] = "save"
    temp.buttons["B3Submit"] = "save"

    result_screen = temp.get_output_xml()
    return result_screen
  end

  def next_seq()
    if on_last? #@current_sequence_index == @sequences.length - 1
      if @parent.pallets_for_trip.length > 1
        if @parent.current_pallet_index < @parent.pallets_for_trip.length - 1
          #>>>>>>>>>>
          persist
          unlock
          #>>>>>>>>>>
          next_state = ValidatePallets.new(self.parent)
          result_screen = next_state.build_default_screen
          self.parent.set_active_state(next_state)
          return result_screen
        else
          @current_sequence_index = @sequences.length - 1
          super
        end
      else
        @current_sequence_index = @sequences.length - 1
        super
      end
    else
      super
    end
  end


  def persist
    @parent.pallets_for_trip.update_pallet_validation(@pallet_no,self)
  end

  def unlock
    @parent.pallets_for_trip.unlock_pallet(@pallet_no.to_s)
  end

  def save()
    
    valid = self.pdt_screen_def.get_control_value("valid")
    if valid.to_s.upcase == "TRUE"
      @sequences[@current_sequence_index][:validated] = true
    else
      @sequences[@current_sequence_index][:validated] = false
    end
    if validation_complete?
      #@parent.pallet_validated(@sequences[@current_sequence_index][:carton_number])
      #>>>>>>>>>>
      persist
      unlock
      #>>>>>>>>>>
      result_screen = @parent.pallet_validated(@pallet_no)
      return result_screen
    else
      next_seq()
    end
  end

  def validation_complete?
    test = true
    for item in @sequences
      if item[:validated] == false
   
#        test = false
        return false
      end
    end
    return test
  end

end