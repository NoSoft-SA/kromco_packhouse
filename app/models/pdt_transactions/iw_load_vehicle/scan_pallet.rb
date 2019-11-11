class ScanPallet < PDTTransactionState

  def initialize(parent)
    @parent = parent
  end
 
  def scan_pallet
    #----------------------------------------
    if(@parent.load_vehicle_completed?)
      return @parent.build_complete_screen
    end
    #----------------------------------------

    #.............................................
      return @parent.confirm_print_tripsheet if(@parent.finished_scanning_pallets?)
    #.............................................
    
    build_default_screen
  end

  #----------------------------------------------
  # builds the default screen for this state
  #----------------------------------------------
  def build_default_screen
#     self.parent.set_cannot_cancel
     self.parent.set_cannot_undo
     field_configs = Array.new
     qty_pallets_required = @parent.qty_pallets_required.to_s
     output_value = "scanned pallets: " + @parent.qty_pallets_scanned.to_s + " of " + qty_pallets_required
     field_configs[field_configs.length] = {:type=>"text_line",:name=>"qty_pallets_to_load",:value=>output_value}
     field_configs[field_configs.length] = {:type=>"text_box",:name=>"pallet_number",:is_required=>"true",:scan_field => true}
     field_configs[field_configs.length] = {:type=>"text_box",:name=>"carton_number",:is_required=>"true",:scan_field => true}
    # field_configs[field_configs.length] = {:type=>"text_box",:name=>"qc_barcode",:scan_only=>"false",:is_required=>"false"}

     screen_attributes = {:auto_submit=>"false",:content_header_caption=>"scan pallets",:cache_screen=>true}
     buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"scan_pallet_submit","B1Label"=>"submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
     plugins = nil
     result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

     return result_screen_def
  end

  def scan_pallet_submit
    validation_error = validate_input
     if validation_error
      field_configs = Array.new
      error_lines = validation_error.to_s.split("!")
      error_lines.each do |err_line|
        if err_line.to_s.strip != ""
          field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>err_line}
        end
      end
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error messages"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"load_vehicle_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
     else
      #----------------------------------------
      if(@parent.load_vehicle_completed?)
        return @parent.build_complete_screen
      end
      #----------------------------------------

      pallet_number = self.parent.get_temp_record("scanned_pallet_number")
      carton_number = PDTFunctions.extract_carton_num(self.pdt_screen_def.get_control_value("carton_number"))
      @parent.scanned_pallets.push(pallet_number.to_s)
      @parent.scanned_cartons.push(carton_number.to_s)
      @parent.qty_pallets_scanned = @parent.qty_pallets_scanned + 1
      
      #.............................................
      return @parent.confirm_print_tripsheet if(@parent.finished_scanning_pallets?)
      #.............................................
      
      return build_default_screen
    end
  end

  def validate_input
    validation_error = nil
    if validation_error = valid_pallet?
    elsif validation_error = valid_carton?
    elsif !valid_ctn_plt_assoc
      validation_error = "carton does not belong to the pallet!"
    elsif validation_error = valid_destination_for_external_qc_result?
    elsif is_internal_qc_required?
      qc_barcode = self.pdt_screen_def.get_control_value("qc_barcode").to_s
      if qc_barcode.to_s.strip == ""
        validation_error = "qc_barcode is required!"
      else
        validation_error = valid_destination_for_internal_qc_result?
      end
    end
    @qc_needed_for = nil
    return validation_error
  end

  def valid_carton?
#    carton_number = self.pdt_screen_def.get_control_value("carton_number")
    carton_number = PDTFunctions.extract_carton_num(self.pdt_screen_def.get_control_value("carton_number"))
    if(!carton_number.to_s.is_numeric?)
      return carton_number
    end
    is_valid = nil
    if @parent.scanned_cartons.include?(carton_number.to_s)
      is_valid = "Carton already scanned!"
    else
      carton = Carton.find_by_carton_number(carton_number)
      if carton == nil
        is_valid = "Carton not found!"
      end
    end
    return is_valid
  end

  def valid_pallet?
    pallet_number = PDTFunctions.extract_pallet_num(self.pdt_screen_def.get_control_value("pallet_number"))
    self.parent.set_temp_record("scanned_pallet_number",pallet_number)
    error = nil
    
    if ! pallet_number.upcase.include?("INVALID")
      error = pallet_number
    end
    
    if @parent.scanned_pallets.include?(pallet_number.to_s)
      error = "Pallet already scanned!"
    else
      pallet = Pallet.find_by_pallet_number(pallet_number)
      if pallet == nil
        error = "Pallet not found!"
      elsif error = un_palletized_pallet?(pallet)
        return error
      elsif error = invalid_destination_for_pallet_on_load?
        return error
      else
        if pallet.get_carton_count != pallet.carton_quantity_actual
          error = "carton qty mismatch(ctns: " + pallet.get_carton_count.to_s + " vs plt: " + pallet.carton_quantity_actual.to_s
        end
	
	stock_item = StockItem.find_by_inventory_reference(pallet.pallet_number)
        if stock_item 
		if stock_item.destroyed
			error = "Pallet is destroyed"
		end
        end
  
      end
    end
    return error
  end

  
    def  un_palletized_pallet?(pallet)
     if pallet.process_status.upcase != "PALLETIZED"
       bay = Bay.get_pallet_in_bay(pallet.pallet_number)
       if !bay
         error = "PALLET unpalletized, but not in any bay"
       else
         skip = bay['skip_code']
         ip = bay['ip_address']
         bay = bay['bay_code']
         error = "PALLET MUST FIRST BE COMPLETED ON BAY!"
         error += "PALLET: " + pallet.pallet_number.to_s + "!"
         error += "SKIP: " + skip + "!"
         error += "SKIP IP: " + ip + "!"
         error += "BAY: " + bay
        end
     end
    
  end

  def valid_ctn_plt_assoc
    is_valid = true
#    carton_number = self.pdt_screen_def.get_control_value("carton_number")
    carton_number = PDTFunctions.extract_carton_num(self.pdt_screen_def.get_control_value("carton_number"))
#    pallet_number = self.pdt_screen_def.get_control_value("pallet_number")
    pallet_number = self.parent.get_temp_record("scanned_pallet_number")
    pallet = Pallet.find_by_pallet_number(pallet_number)
    carton = Carton.find_by_carton_number(carton_number)
    if pallet && carton
      if carton.pallet_id.to_i != pallet.id.to_i
        is_valid = false
      end
    else
      is_valid = false
    end
    return is_valid
  end

  def is_internal_qc_required?
    is_qc_required = false
    if qc_required_for_tm? == true || qc_required_for_org? == true || qc_required_for_sell_by? == true
      is_qc_required = true
    end
    return is_qc_required
  end

  def qc_required_for_tm?
    is_qc_required = false
#    pallet_number = self.pdt_screen_def.get_control_value("pallet_number")
    pallet_number = self.parent.get_temp_record("scanned_pallet_number")
    pallet = Pallet.find_by_pallet_number(pallet_number)
    if pallet
      direct_sales_target_market = DirectSalesTargetMarket.find_by_direct_sales_target_market_code(pallet.target_market_code.split("_")[0])
      if direct_sales_target_market
        is_qc_required = true
        @qc_needed_for = "TM: " + pallet.target_market_code
      end
    end
    puts " TM :: " + is_qc_required.to_s
    return is_qc_required
  end

  def qc_required_for_org?
    is_required = false
#    carton_number = self.pdt_screen_def.get_control_value("carton_number")
    carton_number = PDTFunctions.extract_carton_num(self.pdt_screen_def.get_control_value("carton_number"))
    carton = Carton.find_by_carton_number(carton_number)
    if carton.organization_code == "KR"
      is_required = true
      @qc_needed_for = "ORG: " + carton.organization_code
    end
    puts " ORG :: " + is_required.to_s
    return is_required
  end

  def qc_required_for_sell_by?
    is_required = true
#    carton_number = self.pdt_screen_def.get_control_value("carton_number")
    carton_number = PDTFunctions.extract_carton_num(self.pdt_screen_def.get_control_value("carton_number"))
    carton = Carton.find_by_carton_number(carton_number)
    if carton.sell_by_code.to_s.strip == "" || carton.sell_by_code.to_s.strip == "-"
      is_required = false
    else
      @qc_needed_for = "SELL BY: " + carton.sell_by_code.to_s
    end
    puts " SELL_BY :: " + is_required.to_s
    return is_required
  end


  def kromco_hg_inspection_passed?(pallet)
    validate_msg = nil
    if (pallet.grade_code.upcase() == 'SF' || pallet.grade_code.upcase() == 'SA') && (@parent.destination.to_s.strip != "REWORKS" && @parent.destination.to_s.strip != "RA_10" && @parent.destination.to_s.strip != "PACKHSE")
              inspection = PpecbInspection.find_by_sql("select * from ppecb_inspections where inspection_type_code='KROMCO' and inspection_level_code like 'HG%' AND
                                                       pallet_number = '#{pallet.pallet_number}' order by id desc limit 1")

                  if !inspection[0]
                    validate_msg = "A KROMCO HG inspection has not yet been done. Destination can only be REWORKS or RA_10 or PACKHSE"

                  elsif !inspection[0].passed

                         validate_msg = "KROMCO HG inspection failed for this pallet. "
                          validate_msg += "Destination can only be REWORKS or RA_10 or PACKHSE"
                  end

    end
    return validate_msg

  end

  def valid_destination_for_external_qc_result?
    validate_msg = nil
    #destination = self.pdt_screen_def.get_control_value("destination")
#    pallet_number = self.pdt_screen_def.get_control_value("pallet_number")
    pallet_number = self.parent.get_temp_record("scanned_pallet_number")
    pallet = Pallet.find_by_pallet_number(pallet_number)
    if pallet
      if pallet.qc_result_status.to_s == "FAILED"
        if @parent.destination.to_s.strip != "REWORKS"
          validate_msg = "Destination can only be REWORKS"
        end
      elsif pallet.qc_result_status == nil
        if @parent.destination.to_s.strip != "REWORKS" && @parent.destination.to_s.strip != "RA_10" && @parent.destination.to_s.strip != "PACKHSE"
          validate_msg = "Destination can only be REWORKS or RA_10 or PACKHSE"
          puts "DEST :: " +  @parent.destination.to_s.strip + " LENGTH :: " + @parent.destination.to_s.strip.length.to_s
        end
      else
        #result_status is passed: now check whether pallet passed KROMCO HG inspection if grade = SF or SA
        validate_msg = kromco_hg_inspection_passed?(pallet)

    end


    end
    if validate_msg
      qc_status = pallet.qc_result_status
      qc_status = "not inspected!" if !qc_status
      validate_msg += "!qc_test: external!"
      validate_msg += "qc_status: " + qc_status
    end
    return validate_msg
  end


  def invalid_destination_for_pallet_on_load?
    validate_msg = nil
    pallet_number = self.parent.get_temp_record("scanned_pallet_number")
    pallet = Pallet.find_by_pallet_number(pallet_number)
    if pallet.load_detail_id
      if @parent.destination.to_s.upcase.index("PART_PALLETS")
        validate_msg = "Pallet is on a load. Cannot be moved to a 'PART_PALLETS' destination"
      end
    end

   return validate_msg
  end



  def valid_destination_for_internal_qc_result?
    validate_msg = nil
    scanned_qc_barcode = self.pdt_screen_def.get_control_value("qc_barcode")
    qc_barcode = QcBarcode.find_by_pass_fail_barcode(scanned_qc_barcode)
    if qc_barcode
      if qc_barcode.pass_fail_boolean.to_s.upcase == "FALSE" && @parent.destination.to_s.strip != "REWORKS"
        validate_msg = "Destination can only be REWORKS"
      end
    else
      validate_msg = "Qc_Barcode not in DB"
    end
     if validate_msg
      qc_result = "failed"
      qc_result = "unknown" if !qc_barcode
      qc_result = "passed"  if qc_barcode && qc_barcode.pass_fail_boolean
      
      validate_msg += "!qc_test: internal!"
      validate_msg += "test result: " + qc_result + "!"
      validate_msg += "required by: " + @qc_needed_for
    end
    return validate_msg
  end

end
