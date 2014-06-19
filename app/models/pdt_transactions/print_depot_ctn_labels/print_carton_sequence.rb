class PrintCartonSequence < PalletSequenceNavigator


  def print_carton_sequence
    build_default_screen
  end


  def build_default_screen
    screen_definition = build_sequence_screen
    temp = PdtScreenDefinition.new(screen_definition,nil,PdtScreenDefinition.const_get("ENTERDATA"),nil,nil) #"1.2.2a"
    temp.controls[temp.controls.length()] = {:type=>"text_box",:name=>"enter_qty_labels_to_print",:is_required=>"true", :required_type=>"numeric"}
    temp.screen_attributes["content_header_caption"] = "printing pallet labels for sequence " + (@current_sequence_index + 1).to_s + " of " + @sequences.length.to_s
    temp.buttons["B3Enable"] = "true"
    temp.buttons["B3Label"] = "print_labels"
    temp.buttons["B3Submit"] = "print_labels_submit"

    result_screen = temp.get_output_xml()
    return result_screen
  end

  def build_sequence_screen()
    field_configs = Array.new
    seq_value = (@current_sequence_index + 1).to_s + " of " + @sequences.length.to_s
    #@current_sequence   #[:pallet_sequence_number] if @current_sequence[:pallet_sequence_number] != nil
    
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"sequence",:value=>seq_value}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"fg_code_old",:value=>@current_sequence[:fg_code_old].to_s}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"puc",:value=>@current_sequence[:puc].to_s}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"target_market_code",:value=>@current_sequence[:target_market].to_s}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"pick_reference",:value=>@current_sequence[:pick_reference].to_s}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"inventory_code",:value=>@current_sequence[:inventory_code].to_s}

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"print depot pallet labels"}
    if @current_sequence_index == 0
         buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    elsif @current_sequence_index == @sequences.length - 1
       buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"false","B2Enable"=>"true","B3Enable"=>"false" }
    else
       buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
    end
    #buttons = {"B3Label"=>"Clear" ,"B2Label"=>"next", "B2Submit"=>"next_seq", "B1Submit"=>"prev_seq","B1Label"=>"prev","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def calc_sequences()
    mapped_pallet_sequences = MappedPalletSequence.find_by_sql("SELECT * FROM mapped_pallet_sequences WHERE depot_pallet_number='#{@pallet_no}'")
    mapped_pallet_sequences.each do |mapped_pallet_sequence|
      @sequences[@sequences.length] = {:id => mapped_pallet_sequence.id, :fg_code_old=>mapped_pallet_sequence.fg_code_old,:puc=>mapped_pallet_sequence.puc,:pick_reference=>mapped_pallet_sequence.pick_reference,:target_market_code=>mapped_pallet_sequence.target_market,:inventory_code=>mapped_pallet_sequence.inventory_code,:pallet_number=>@pallet_no}
    end
  end

  def print_labels_submit()
    puts "---- HERE ---"
    mapped_pallet_sequence = @sequences[@current_sequence_index]
    amount = self.pdt_screen_def.get_control_value("enter_qty_labels_to_print")
    printed = Carton.print_depot_labels(mapped_pallet_sequence[:id], amount)
    puts " --- OUT OF HERE ---"
    if printed
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"pallet labels printed successifully!"}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"labels printed"}
      if @current_sequence_index > 0
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev","B1Submit"=>"next_seq","B1Label"=>"next", "B2Submit" =>"prev_seq", "B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
      else
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"next_seq","B1Label"=>"next", "B2Submit" =>"prev_seq", "B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
      end
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    else
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"error occurred while trying to print labels"}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error messages"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"print_labels_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    end
  end

end
