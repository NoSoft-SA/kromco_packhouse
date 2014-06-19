class FirstIntake < PDTTransaction
  
  attr_accessor :pallet_number, :consignment,:intake_header_id

  def new_pallet()

    pallet_format_codes = PalletFormatProduct.find(:all).map{|p|[p.pallet_format_product_code]}.join(",")
    @cons_no = "" if !@cons_no

    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_pallet",:is_required=>"true"}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"consignment", :label=>"scan consignment", :value=>@cons_no, :is_required=>"true"}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"carton_quantity",:is_required=>"true", :required_type=>"number"}
    field_configs[field_configs.length] = {:type=>"drop_down",:name=>"pallet_format",:is_required=>"true",:list => pallet_format_codes}

    screen_attributes = {:auto_submit=>"true",:auto_submit_to=>"new_pallet_submit",:content_header_caption=>"new pallet"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"new_pallet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def get_pallet()
    
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_pallet",:is_required=>"true"}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"consignment", :label=>"scan consignment", :is_required=>"true"}

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"get pallet"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"get_pallet_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def new_pallet_submit()
    pallet_num = self.pdt_screen_def.get_control_value("scan_pallet").to_s.strip
    pallet_format = self.pdt_screen_def.get_control_value("pallet_format").to_s.strip
    consignment = self.pdt_screen_def.get_control_value("consignment").to_s.strip
    @cons_no =  consignment
    carton_quantity = self.pdt_screen_def.get_control_value("carton_quantity").to_s.strip
    pal_validation = validate_new_pallet_input(pallet_num, consignment)
    if pal_validation.to_s.is_numeric?
      ActiveRecord::Base.transaction do
        @pallet_number = pal_validation
        @consignment = consignment
        depot_pallet = DepotPallet.new
        depot_pallet.depot_pallet_number = @pallet_number
        intake_header = IntakeHeader.find_by_sql("SELECT * FROM intake_headers WHERE consignment_note_number ='#{consignment}' and upper(header_status) <> 'EDI_RECEIVED' and upper(header_status) <> 'CANCELED' ORDER BY id DESC")[0]
         #to force status calculation
        depot_pallet.intake_header_id = intake_header.id
        depot_pallet.carton_quantity = carton_quantity.to_s
        depot_pallet.pallet_format_product_code = pallet_format
        depot_pallet.create
        intake_header.update
      end
      
      next_state = SequenceCrud.new(self)
      result_screen = next_state.build_default_screen
      self.set_active_state(next_state)
      return result_screen
    else
      # Error
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>pal_validation.to_s}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error messages"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"get_pallet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    end
  end

  def get_pallet_submit()
    pallet_num = self.pdt_screen_def.get_control_value("scan_pallet").to_s.strip
    consignmt = self.pdt_screen_def.get_control_value("consignment").to_s.strip
    validation_msg = validate_get_pallet_input(pallet_num, consignmt)
    if validation_msg.to_s.is_numeric?
      # transit to SequenceCrud State
      @pallet_number = validation_msg
      @consignment = consignmt
      next_state = SequenceCrud.new(self)
      result_screen = next_state.build_default_screen
      self.set_active_state(next_state)
      return result_screen
    else
      # Error
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>validation_msg.to_s}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error messages"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"get_pallet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    end
  end

  def validate_get_pallet_input(pallet_num, consignment)
    intake_header = IntakeHeader.find_by_sql("SELECT * FROM intake_headers WHERE consignment_note_number ='#{consignment}' and upper(header_status) <> 'EDI_RECEIVED' and upper(header_status) <> 'CANCELED' ORDER BY id DESC")[0]
  
    if intake_header
      self.intake_header_id = intake_header.id
      if intake_header.header_status == "LOAD_RECEIVED"||intake_header.header_status == "EDI_REQUESTED"||intake_header.header_status == "EDI_SENT"
        return "load already received"
      end
      pallet_num = PDTFunctions.extract_pallet_num(pallet_num)
      if !pallet_num.upcase.include?("INVALID")
        depot_pallet = DepotPallet.find_by_depot_pallet_number_and_intake_header_id(pallet_num, intake_header.id)
        if depot_pallet
          return pallet_num
        else
          return "Depot Pallet does not exist!"
        end
      else
        return pallet_num
      end
    else
      return "Intake header not found!"
    end
  end

  def validate_new_pallet_input(pallet_num, consignment)
    intake_header = IntakeHeader.find_by_sql("SELECT * FROM intake_headers WHERE consignment_note_number ='#{consignment}' and upper(header_status) <> 'EDI_RECEIVED' and upper(header_status) <> 'CANCELED' ORDER BY id DESC")[0]

    if intake_header
      self.intake_header_id = intake_header.id
      if intake_header.header_status == "LOAD_RECEIVED"||intake_header.header_status == "EDI_REQUESTED"||intake_header.header_status == "EDI_SENT"
        return "load already received"
      end

       if intake_header.header_status == "MAPPING_COMPLETE"
        return "load already mapped"
       end

      depot_pallets = DepotPallet.find_by_sql("SELECT * FROM depot_pallets WHERE intake_header_id = '#{intake_header.id}'")
      if depot_pallets.length < intake_header.qty_pallets.to_i
        pallet_num  = PDTFunctions.extract_pallet_num(pallet_num)
        if !pallet_num.upcase.include?("INVALID")
          stock_item = StockItem.find_by_inventory_reference(pallet_num)
          if stock_item
            return "Pallet already in inventory!"
          else
            depot_pallet = DepotPallet.find_by_depot_pallet_number_and_intake_header_id(pallet_num, intake_header.id)
            if depot_pallet
              return "Depot Pallet already exists!"
            else
              return pallet_num
            end
          end
        else
          return pallet_num
        end
      else
        return "Depot Pallet cannot be created, pallets quantity required for this consignment will be exceeded"
      end
    else
      return "Intake header not found!"
    end
  end

end
