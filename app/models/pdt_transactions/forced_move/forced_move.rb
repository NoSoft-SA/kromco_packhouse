 class ForcedMove < PDTTransaction

  def force_move
    build_default_screen
 
  end

  def build_default_screen
    #-----------------------------------------------
    # Client side filtering
    #-----------------------------------------------
    field_configs = Array.new


    field_configs[field_configs.length] = {:type=>"text_box",:name=>"pallet_number",:label=>"scan pallet",:value=>"",:is_required=>true, :scan_field => true}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_location",:label=>"scan location",:value=>"",:is_required=>true, :scan_field => true}
    screen_attributes = {:auto_submit=>"true",:content_header_caption=>"force move",:auto_submit_to=>"force_move_submit"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Submit"=>"force_move_submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = Array.new
    #plugins[plugins.length] = {:class_name=>'LabelPlugin',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
    return result_screen_def
  end





  def validate_input
    extracted_pallet_num = PDTFunctions.extract_pallet_num(@scratch_pad["pallet_number"])
    #if extracted_pallet_num.kind_of?(Fixnum) || extracted_pallet_num.kind_of?(Bignum)
    if !extracted_pallet_num.upcase.include?("INVALID")
      pallet_record =  Pallet.find_by_pallet_number(extracted_pallet_num)

      if(pallet_record != nil)
#        if pallet_record.load_detail_id
#           additonal_lines_array = ["ERROR MSG : PALLET IS ON A LOAD!" ]
#          result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
#          return result_screen
#        end
        @scratch_pad["scan_pallet_record"] = pallet_record
        @scratch_pad["pallet_number"] = extracted_pallet_num
         
        valid_location
      else
        additonal_lines_array = ["ERROR MSG : INVALID PALLET  "+@scratch_pad["pallet_number"].to_s+" NOT FOUND " ]
        result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
        return result_screen
      end
    else
      additonal_lines_array = [extracted_pallet_num ]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
    end

  end

  def force_move_trans

    ActiveRecord::Base.transaction do
    stockitem   =   @scratch_pad["stock_item_record"]

    stockitem.location_id = @scratch_pad["location_barcode_record"].id.to_s


    stockitem.location_code =  @scratch_pad["location_barcode_record"].location_code

    Inventory.move_stock('forced_move','forced_move',@scratch_pad["location_barcode_record"].location_code,[@scratch_pad["pallet_number"]])

    set_repeat_process_flag
    return nil
#    additonal_lines_array = [" MSG : pallet transfered to its new location  " ]
#    result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
#    return result_screen
    end
  end

  def get_to_location_rules(to_locn_code)
    to_locn = Location.find_by_location_code(to_locn_code)
    to_location_rules = ForceLocationRule.find_all_by_force_to(to_locn_code)
    if  to_location_rules.length() > 0
      return  to_location_rules
    else
      if(to_locn.parent_location_code)
         get_to_location_rules(to_locn.parent_location_code)
      else
         return nil
      end
    end
  end

  def extract_force_location_rule(to_location_rules,from_location)
    to_location_rules.each do |rule|
      if(rule.force_from == from_location.location_code)
        return rule
#        break
      end
    end

    unless from_location.parent_location_code.to_s == from_location.location_code
      from_locn_parent = Location.find_by_location_code(from_location.parent_location_code)
      extract_force_location_rule(to_location_rules,from_locn_parent) if from_locn_parent != nil
    end

  end

  def get_force_location_rule(from_location,to_location)
    to_location_rules = get_to_location_rules(to_location)
    if(to_location_rules && to_location_rules.length > 0)

      forcelocation_rule = extract_force_location_rule(to_location_rules,from_location)
      return forcelocation_rule
    end
    return nil
  end

  def valid_location
    #  puts "Im in valid location"
    location = Location.find_by_location_barcode(@scratch_pad["scan_location"])

    #  puts "dddd this is the location barcode id  " +location_barcode.location_code.to_s
    @scratch_pad["location_barcode_record"] = location
    if(location != nil)
#      pallet_record =   @scratch_pad["scan_pallet_record"]
#      if location.unavailable
#         additonal_lines_array = [" MSG : location is not available " ]
#         result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
#         return result_screen
#      end
      stockitem_record =  StockItem.find_by_inventory_reference(@scratch_pad["pallet_number"])
      @scratch_pad["stock_item_record"] = stockitem_record
      if(stockitem_record !=  nil)
        force_from = stockitem_record.location_code
        force_to = location.location_code
#        forcelocation_rules = get_force_location_rule(Location.find_by_location_code(force_from),force_to) #old
        forcelocation_rules = search_force_location_rule(Location.find_by_location_code(force_from),force_to) #new
        @scratch_pad["force_locations_rules"] = forcelocation_rules
        if(forcelocation_rules != nil)
          #pallet on load rule
          pallet = Pallet.find_by_pallet_number(@scratch_pad["pallet_number"])
          if pallet.load_detail_id && location.location_code.upcase.index("PART_PALLETS")
            result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,['Pallet is on a load.Move to PART_PALLET not allowed'])
            return result_screen
          else
           return  force_move_trans
          end
        else
          additonal_lines_array = [" MSG : FORCE XFER FROM[#{force_from}] TO[#{force_to}] NOT ALLOWED " ]
          result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
          return result_screen
        end
      else
        additonal_lines_array = [" MSG : STOCK ITEM NOT FOUND " ]
        result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
      end
    else
      additonal_lines_array = [" MSG : the location barcode does not  exists "+@scratch_pad["scan_location"].to_s ]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
      return result_screen
    end
  end

  def search_force_location_rule(from_location,to_location)
    if(forcelocation_rules = get_force_location_rule(from_location,to_location))
      return forcelocation_rules
    else
      if(!(to_location_rec = Location.find_by_location_code(to_location)))
        return nil
      end
      if(to_locn_parent = Location.find_by_location_code(to_location_rec.parent_location_code))
        return search_force_location_rule(from_location,to_locn_parent.location_code)
      end
    end
    return nil
  end


  def force_move_submit
    @scratch_pad["pallet_number"] = self.pdt_screen_def.get_input_control_value("pallet_number")
    @scratch_pad["scan_location"] = self.pdt_screen_def.get_input_control_value("scan_location")
    validate_input
  end
end

