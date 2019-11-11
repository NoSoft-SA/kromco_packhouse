class CreatePallet < PDTTransaction

  def create_pallet
    if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
      build_default_screen
    else
      create_pallet_submit
    end
  end

  def build_default_screen()
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_carton_or_pallet", :label=>"scan carton or pallet", :is_required=>"true", :scan_field => true}
    field_configs[field_configs.length] = {:type=>"drop_down",:name=>"pallet_format_product", :list_field=>"pallet_format_product_code", :get_list=>"get_pallet_format_product_codes"}

     screen_attributes = {:auto_submit=>"false",:content_header_caption=>"create new pallet"}
     buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"create_pallet_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
     plugins = nil
     result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

     return result_screen_def
  end

  def create_pallet_submit()
    errors = Array.new
    carton_number = PDTFunctions.extract_carton_num(self.pdt_screen_def.get_control_value("scan_carton_or_pallet")).to_s
    if(!carton_number.to_s.is_numeric?)
      errors.push(carton_number)
      pallet_number = PDTFunctions.extract_pallet_num(self.pdt_screen_def.get_control_value("scan_carton_or_pallet"))
      if(!pallet_number.upcase.include?("INVALID"))
        pallet = Pallet.find_by_pallet_number(pallet_number)
        if(pallet)
          carton = pallet.get_oldest_carton
          if(carton)
            carton_number = carton.carton_number.to_s
            errors = Array.new
          else
            errors = ["scanned pallet has no cartons"]
          end
        else
          errors = ["scanned pallet not found"]
        end
      else
        errors.push(pallet_number)
      end
    end

    return PDTTransaction.build_msg_screen_definition("errors:",nil,nil,errors) if(errors.length > 0)

    pallet_format_product_code = self.pdt_screen_def.get_control_value("pallet_format_product")
    carton_valid = validate_input(carton_number)
    if carton_valid == nil
      ActiveRecord::Base.transaction do
        pallet = @carton.create_pallet(pallet_format_product_code,true,true)
        fg_product = FgProduct.find_by_fg_product_code(@carton.fg_product_code)
        pallet.carton_quantity_actual = 1
        pallet.oldest_pack_date_time = Time.now()
        err = Pallet.set_build_status(fg_product.carton_pack_product_code,pallet)
        pallet.create
        source_pallet_num =   @carton.pallet_number

        @carton.pallet_number = pallet.pallet_number
        @carton.pallet_id = pallet.id
        @carton.update

        raise err if err


        source_pallet = nil
        if pallet.pallet_number != nil
          
          if @carton.pallet_number
             source_pallet = Pallet.find_by_pallet_number(source_pallet_num)
             source_pallet.carton_quantity_actual -= 1
             source_pallet.update
          end

          
          pallet.load_detail_id = source_pallet.load_detail_id
	  pallet.is_depot_pallet = source_pallet.is_depot_pallet
	  if pallet.organization_code == "TI"||pallet.is_depot_pallet.to_s.upcase == "TRUE"
             pallet.consignment_note_number = source_pallet.consignment_note_number
	  end
          pallet.ppecb_inspection_id = source_pallet.ppecb_inspection_id
          pallet.zero_printed_carton_labels = source_pallet.zero_printed_carton_labels




          pallet.update







          stock_item = StockItem.find_by_inventory_reference(source_pallet.pallet_number)
          raise "source pallet not yet on stock" if ! stock_item
          pallet_location =  stock_item.location_code
          pallet.location_code =  pallet_location

          Inventory.create_stock(nil, "PALLET", nil, nil, "buildup_create_pallet", nil, pallet_location, [pallet.pallet_number])
          #NewOutboxRecord.new("pallet_new",pallet)
          #NewOutboxRecord.new("carton_pallet_ref_change",@carton)
          
          set_transaction_complete_flag
          field_configs = Array.new
          field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"pallet[" + pallet.pallet_number.to_s + "] created successifully!"}
          field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"source_pallet is [" + source_pallet.pallet_number.to_s + "] "}

          screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transaction complete"}
          buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"create_pallet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
          return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
        else
          # failure pallet not created
          field_configs = Array.new
          field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"Pallet could not be created."}
          screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error message"}
          buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"create_pallet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
          return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
        end
      end
    else
      # error carton not found
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=> carton_valid.to_s}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error message"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"create_pallet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    end
  end

  def validate_input(carton_number)
    carton_number = PDTFunctions.extract_carton_num(carton_number)
    
    if !carton_number.to_s.is_numeric?
      return "Carton number must be of numeric type!"
    else
      @carton = Carton.find_by_carton_number(carton_number)
      if @carton
        if @carton.pallet.exit_ref
          return "Pallet has exit_ref: " + @carton.pallet.exit_ref
        end
        return nil
      else
        return "Scanned carton doesn't exist!"
      end
    end
  end

end
