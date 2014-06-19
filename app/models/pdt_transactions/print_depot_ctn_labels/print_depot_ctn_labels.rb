class PrintDepotCtnLabels < PDTTransaction

  attr_accessor :pallet_number


  def print_depot_ctn_labels
    if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
     build_default_screen
   else
     print_depot_ctn_labels_submit
   end
  end

  def build_default_screen()
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_pallet",:is_required=>"true"}
    
    screen_attributes = {:auto_submit=>"true",:content_header_caption=>"scan depot pallet",:auto_submit_to=>"print_depot_ctn_labels_submit"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"print_depot_ctn_labels_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def print_depot_ctn_labels_submit()
    validate_msg = validate_input
    if validate_msg.to_s.strip == ""
      next_state = PrintCartonSequence.new(self, @pallet_number)
      result_screen = next_state.build_default_screen
      self.set_active_state(next_state)
      return result_screen
    else
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>validate_msg.to_s}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error messages"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"print_depot_ctn_labels_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    end
  end

  def validate_input()
    @pallet_number = self.pdt_screen_def.get_input_control_value("scan_pallet")
    pallet = Pallet.find_by_pallet_number(@pallet_number)
    if pallet
      if pallet.is_depot_pallet
        return ""
      else
        return "scanned pallet is not a depot pallet!"
      end
    else
      return "depot pallet does not exist!"
    end
  end

end
