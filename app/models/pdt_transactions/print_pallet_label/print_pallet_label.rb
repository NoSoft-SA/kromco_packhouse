class PrintPalletLabel < PrintPalletLabelBase


  def print_pallet_label()
    if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
      build_default_screen
    else
      print_pallet_label_submit
    end
  end

  def build_default_screen()
    screen_definition = super
    temp = PdtScreenDefinition.new(screen_definition, nil, PdtScreenDefinition.const_get("ENTERDATA"), nil, nil)
    temp.buttons["B1Submit"] = "print_pallet_label_submit"
    result_screen = temp.get_output_xml()
    return result_screen
  end


  def log_pallet_label_print (print_string)
   ActiveRecord::Base.transaction do
    label = LabelLog.new
    label.label_code = print_string
    label.label_name = "print_pallet_label"
    label.label_type_id = LabelType.find_by_label_type_code("PALLET").id
    label.create

    pallet = Pallet.find_by_pallet_number(@pallet_number)

    pallet.n_labels_printed=0 if !pallet.n_labels_printed
    pallet.n_labels_printed += 1

    if pallet.n_labels_printed > 1
      pallet.reprint_acknowledged_by=self.pdt_screen_def.user
      pallet.reprint_acknowledged_date_time =Time.now
    end

    pallet.update
    Inventory.create_stock(nil, "PALLET", nil, nil, "PALLET_LABEL_PRINTING", pallet.pallet_number, 'PACKHSE', pallet.pallet_number)
    Order.get_and_upgrade_prelim_orders([pallet.pallet_number])
   end

  end


  def print_pallet_label_submit()


      print_string = ""
      error_msg = print_pallet_label_base_submit(print_string)
      if !error_msg
        # creation of labels record
         log_pallet_label_print (print_string)

         build_default_screen
#        field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"transaction completed successifully!"}
#        screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transaction complete"}
#        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"print_pallet_label_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
#        return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
      else
        return error_msg
      end

  end


end
