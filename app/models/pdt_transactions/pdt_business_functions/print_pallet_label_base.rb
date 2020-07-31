class PrintPalletLabelBase < PDTTransaction

  attr_accessor :pallet_number, :printer,:printed_string

  def print_pallet_label_base()
    if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
      build_default_screen
    else
      print_pallet_label_base_submit
    end
  end

  def build_default_screen()
    field_configs                       = Array.new
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"printer", :label=>"scan printer", :is_required=>"true"}
    #field_configs[field_configs.length] = {:type=>"text_box", :name=>"n_labels_to_print", :label=>"print qty"}
    field_configs[field_configs.length] = {:type=>"drop_down", :name=>"n_labels_to_print", :label=>"print qty", :list=>"1,2,3,4"}
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"carton_or_pallet", :label=>"scan ctn or plt", :is_required=>"true",:scan_field => true,:submit_form => true}

    screen_attributes                   = {:auto_submit=>"false", :content_header_caption=>"scan carton or pallet and printer"}
    buttons                             = {"B3Label"=>"Clear" ,"B2Label"=>"", "B2Submit"=>"", "B1Submit"=>"print_pallet_label_base_submit","B1Label"=>"submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }

    plugins                             = nil
    result_screen_def                   = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def print_pallet_label_base_submit(printed_string)

    error_msg = validate_input
    if error_msg.to_s.strip == ""
      choice_screen = check_labels_printed(printed_string)
      return choice_screen
    else
      field_configs = Array.new
      error_lines   = error_msg.to_s.split("|")
      error_lines.each do |err_line|
        field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>err_line}
      end
      screen_attributes = {:auto_submit=>"false", :content_header_caption=>"error messages"}
      buttons           = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Submit"=>"print_pallet_label_base_submit", "B1Label"=>"Submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    end
  end

  def check_labels_printed (print_string)
     pallet = Pallet.find_by_pallet_number(@pallet_number)
     n_labels_printed =  pallet.n_labels_printed
     n_labels_printed =  0 if !  pallet.n_labels_printed

     if n_labels_printed >= 1
        outputs = ["#{n_labels_printed} " +
                  "pallet labels have been printed for this pallet " ,
                 "Are you sure you want to reprint them?", nil, nil]
      return self.build_choice_screen(outputs)
      else
       print_string << re_print_pallet_label_base_submit
       return nil
      end
   end

  def re_print_pallet_label_base_submit()
      return print_pallet_label_trans

  end

  def yes
    print_string = re_print_pallet_label_base_submit
    log_pallet_label_print (print_string)
     build_default_screen
  end

  def no
    re_printing_cancelled
  end

  def re_printing_cancelled
    build_default_screen
  end

  def print_pallet_label_trans()

    label_print_cmd = PalletPrintCommand.new(@printer.to_s, "E1", @labels_to_print)
    print           = label_print_cmd.print(@object_number)
    return print

  end

  def validate_input()

    carton_or_pallet = self.pdt_screen_def.get_control_value("carton_or_pallet")
    @printer         = self.pdt_screen_def.get_control_value("printer")
    @labels_to_print = self.pdt_screen_def.get_control_value("n_labels_to_print").to_i
    @labels_to_print = 1 if @labels_to_print == 0

    self.set_temp_record("printer", @printer)
    carton = nil
    pallet = nil


    #-------------------------------------------
    #extract carton number if carton was scanned
    #-------------------------------------------
    if carton_or_pallet.to_s.strip.length == 13||carton_or_pallet.to_s.strip.length == 12
      carton_or_pallet = carton_or_pallet.strip().slice(0..11)
      if carton_or_pallet.to_s.is_numeric?
        carton = Carton.find_by_carton_number(carton_or_pallet.to_s.strip)
        if carton == nil
          return "carton scanned does not exist|"
        else
          if !carton.pallet_number
            return "carton does not belong to a pallet"
          else
            self.set_temp_record("carton", carton)
            @object_number = carton.carton_number
            pallet         = Pallet.find_by_pallet_number(carton.pallet_number)
            @pallet_number = pallet.pallet_number
            return "pallet: " + carton.pallet_number.to_s + " not found" if !pallet
          end
        end
      else
        return "carton or pallet number must be a numeric value|"
      end
    else
      #-------------------------------------------
      #extract carton number if carton was scanned
      #-------------------------------------------
      pallet_num = PDTFunctions.extract_pallet_num(carton_or_pallet)
      if !pallet_num.upcase.include?("INVALID")
        @object_number = pallet_num
        pallet         = Pallet.find_by_pallet_number(@object_number)
        if (!pallet)
          return "carton or pallet scanned does not exist|"
        end
        @pallet_number = pallet.pallet_number
      else
        return pallet_num
      end
    end


    #------------------------
    #do validations on pallet
    #------------------------

    if pallet.pallet_reno_ref != nil
      return "pallet relabeled(" + pallet.pallet_reno_ref.to_s + ")"
    end

    if pallet.exit_ref && pallet.exit_ref.upcase == "SCRAPPED"
      return "Pallet has been scrapped"
    end
    #make sure pallet has cartons
    ctn_count = Pallet.connection.select_one("select count(*) as ctn_count from cartons where pallet_number = '#{pallet.pallet_number.to_s}'")
    return "Pallet has no cartons" if ctn_count['ctn_count'].to_i == 0
    if pallet.is_depot_pallet.to_s.upcase == "TRUE" && (pallet.is_mapped == nil || pallet.is_mapped.to_s.upcase == "FALSE")
      return "pallet not mapped|"
    end

  end


end
