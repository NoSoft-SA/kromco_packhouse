class PrintCompositePalletLabel < PrintPalletLabelBase

  def print_composite_pallet_label()
    if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
      build_default_screen
    else
      print_composite_pallet_label_submit
    end
  end

  def build_default_screen()
    screen_definition = super
    temp = PdtScreenDefinition.new(screen_definition,nil,PdtScreenDefinition.const_get("ENTERDATA"),nil,nil)
    temp.buttons["B1Submit"] = "print_composite_pallet_label_submit"
    result_screen = temp.get_output_xml()
    return result_screen
  end

  def print_composite_pallet_label_submit()
     error_msg = validate_input
    if error_msg.to_s.strip == ""
      ActiveRecord::Base.transaction do
        print_pallet_label_trans

        # to print the composite pallet label
        label_print_command = LabelPrintCommand.new(self.scratch_pad["printer"], "W5")
        carton_groups = Carton.find_by_sql("SELECT puc, count(*) AS puc_count FROM cartons where pallet_number = '#{@pallet_number}' GROUP BY puc")
        if carton_groups.length != 0
          for carton in carton_groups
            cartons_rep = Carton.find_by_sql("SELECT variety_short_long, fg_product_code from cartons where puc = '#{carton.puc}' and pallet_number ='#{@pallet_number}'")[0]
            marketing_variety_code = cartons_rep.variety_short_long.to_s.split("_")[0]
            fg_product = FgProduct.find_by_fg_product_code(cartons_rep.fg_product_code)
            item_pack_product = ItemPackProduct.find_by_item_pack_product_code(fg_product.item_pack_product_code)
            size_ref = item_pack_product.size_ref
            if size_ref == "NOS"
              size_ref = item_pack_product.actual_count
            end
            # create the format string
            #label_print_command.set_print_field(" i dont know for now", "i dont know")
          end
        end

        #label_print_command.print()

        field_configs = Array.new
        field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"print composite pallet label completed successifully!"}
        screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transaction complete"}
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"print_composite_pallet_label_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
        return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
      end
    else
      
    end
  end

end
