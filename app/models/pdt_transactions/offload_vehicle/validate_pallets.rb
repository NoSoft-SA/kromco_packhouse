class ValidatePallets < PDTTransactionState
  
  def initialize(parent)
    @parent = parent
  end

  def validate_pallets
    build_default_screen
  end

  def list_validated_pallets
    @parent.render_list_validated_pallets
  end

  def list_invalidated_pallets
    @parent.render_list_invalidated_pallets
  end

  def build_default_screen
     field_configs = Array.new
     field_configs[field_configs.length] = {:type=>"static_text",:name=>"qty_of_pallets_to_validate",:label => "to_validate", :value=>@parent.pallets_for_trip.length.to_s}
     field_configs[field_configs.length] = {:type=>"static_text",:name=>"qty_of_pallets_remaining",:label => "remaining",:value=>@parent.not_yet_validated_pallets.length.to_s }
     field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_pallet_to_validate",:label => "plt",:is_required=>"true"}

     screen_attributes = {:auto_submit=>"false",:content_header_caption=>"validate pallets"}
    if @parent.pallets_for_trip.length > 1
      if @parent.current_pallet_index == 0
         buttons = {"B3Label"=>"submit" , "B3Submit" =>"validate_pallets_submit", "B2Label"=>"prev", "B2Submit"=>"prev_plt", "B1Submit"=>"next_plt","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"true" }
       elsif @parent.current_pallet_index == @parent.pallets_for_trip.length - 1
          buttons = {"B3Label"=>"submit" , "B3Submit" =>"validate_pallets_submit", "B2Label"=>"prev", "B2Submit"=>"prev_plt", "B1Submit"=>"next_plt","B1Label"=>"next","B1Enable"=>"false","B2Enable"=>"true","B3Enable"=>"true" }
       else
          buttons = {"B3Label"=>"submit" ,"B3Submit" =>"validate_pallets_submit", "B2Label"=>"prev", "B2Submit"=>"prev_plt", "B1Submit"=>"next_plt","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"true" }
       end
    else
      buttons = {"B3Label"=>"submit" ,"B3Submit" =>"validate_pallets_submit", "B2Label"=>"prev", "B2Submit"=>"prev_plt", "B1Submit"=>"next_plt","B1Label"=>"next","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"true" }
    end
     #buttons = {"B3Label"=>"Clear" ,"B2Label"=>"next", "B2Submit"=>"next_seq", "B1Submit"=>"prev_seq","B1Label"=>"prev","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
     plugins = nil
     result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

     return result_screen_def
  end

  def validate_pallets_submit
    #..........................................
    #..........................................
    if(masg_screen = @parent.process_disrupted?)
      return masg_screen
    end 
    #..........................................
    #..........................................
    @pallet_number = self.pdt_screen_def.get_control_value("scan_pallet_to_validate")
    validate_msg = validate_input
    if validate_msg.to_s.strip == ""
      pallet_validation = @parent.getPalletValidation(@pallet_number)
      next_state = pallet_validation
      result_screen = next_state.validate_pallet()
      self.parent.set_active_state(next_state)
      return result_screen
    else
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>validate_msg}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error messages",:cache_screen=>true}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"load_vehicle_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    end
  end

  def is_valid_tripsheet_pallet?(pallet_number)
    @parent.pallets_for_trip.each do |pal|
      if(pal.kind_of?(String))
        if(pal == pallet_number)
          return true
        end
      elsif(pal.kind_of?(PalletValidation))
        if(pal.pallet_no == pallet_number)
          return true
        end
      end
    end
    return false
  end
  
  def validate_input
    valid_msg = ""
    #pallet_number = self.pdt_screen_def.get_control_value("scan_pallet_to_validate").to_i
    scanned_pallet_number = PDTFunctions.extract_pallet_num(@pallet_number)
    if !scanned_pallet_number.upcase.include?("INVALID") #used to be numericality chack
      @pallet_number = scanned_pallet_number
      if is_valid_tripsheet_pallet?(scanned_pallet_number.to_s)
        if(@parent.validated_pallets.include?(scanned_pallet_number.to_s))
          valid_msg = "Palle[#{scanned_pallet_number}]t has already been validated"
        else
          return ""
        end
      else
         valid_msg = "Pallet [" + scanned_pallet_number.to_s + "] does not belong to this trip"
      end
    else
      valid_msg = scanned_pallet_number
    end
    
    return valid_msg
  end

  def next_plt
    if(masg_screen = @parent.process_disrupted?)
      return masg_screen
    end

    pallet_validation = @parent.next_pallet()
    if pallet_validation.is_a?(PalletValidation)
      next_state = pallet_validation
      result_screen = next_state.validate_pallet()
      self.parent.set_active_state(next_state)
      return result_screen
      #pallet_validation.validate_pallet()
    else
      build_default_screen
    end
  end

  def prev_plt
    if(masg_screen = @parent.process_disrupted?)
      return masg_screen
    end

    pallet_validation = @parent.prev_pallet()
    if pallet_validation.is_a?(PalletValidation)
      next_state = pallet_validation
      result_screen = next_state.validate_pallet()
      self.parent.set_active_state(next_state)
      return result_screen
      #pallet_validation.validate_pallet()
    else
      build_default_screen
    end
  end

end
