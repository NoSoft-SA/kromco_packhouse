class PalletEnquiry < PDTTransaction

  def pallet_enquiry
    build_default_screen
  end

  def build_default_screen

    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'carton_or_pallet',
                                           :label=>'carton_or_pallet',:is_required=>'true'}
    buttons = {:B1Label=>"Submit",:B1Enable=>"false",:B1Submit=>"pallet_enquiry_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"scan carton or pallet",:auto_submit=>"true",:auto_submit_to=>"pallet_enquiry_submit"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end

  def pallet_enquiry_submit
    pallet_number = self.pdt_screen_def.get_input_control_value("carton_or_pallet")
    set_temp_record("carton_or_pallet_num", pallet_number)

    if (error = validate_input) == nil
      pallet = get_temp_record('pallet')

        next_state = PalletViewer.new(self,pallet.pallet_number)
        result_screen = next_state.build_default_screen()
        self.set_active_state(next_state)
        return result_screen

    else
        additonal_lines_array = [error.to_s]
        result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
        return result_screen
    end
  end



    def validate_input()

    carton_or_pallet = self.pdt_screen_def.get_control_value("carton_or_pallet")

    carton = nil
    pallet = nil

    #------------------------------------------
    #extract carton number if carton was scanned
    #-------------------------------------------
    if carton_or_pallet.to_s.strip.length == 13||carton_or_pallet.to_s.strip.length == 12
      carton_or_pallet = carton_or_pallet.strip().slice(0..11)
      if carton_or_pallet.to_s.is_numeric?
        carton = Carton.find_by_carton_number(carton_or_pallet.to_s.strip)
        if carton == nil
          return "carton scanned does not exist|"
        else
          if ! carton.pallet_number
            return "carton does not belong to a pallet"
          else
            pallet = Pallet.find_by_pallet_number(carton.pallet_number)
            set_temp_record("pallet",pallet)
            return "pallet: " + carton.pallet_number.to_s + " not found" if ! pallet
          end
        end
      else
        return "carton or pallet number must be a numeric value|"
      end
    else
    #-------------------------------------------
    #extract carton number if carton was scanned
    #-------------------------------------------
      RAILS_DEFAULT_LOGGER.info("pallet_enquiry.rb: 74 - carton_or_pallet: " + carton_or_pallet)
      pallet_num = PDTFunctions.extract_pallet_num(carton_or_pallet)
      RAILS_DEFAULT_LOGGER.info("pallet_enquiry.rb: 74 - pallet_num: " + pallet_num)

      if !pallet_num.upcase.include?("INVALID")
        pallet = Pallet.find_by_pallet_number(pallet_num)
        if(!pallet)
          return "carton or pallet scanned does not exist|"
        end
        set_temp_record("pallet",pallet)
        set_temp_record("carton_or_pallet_num", pallet.pallet_number)
      else
        return pallet_num
      end
    end


    #------------------------
    #do validations on pallet
    #------------------------

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


  def validate_input_old
    extracted_pallet_num = PDTFunctions.extract_pallet_num(@scratch_pad["pallet_number"])
    #if extracted_pallet_num.kind_of?(Fixnum) || extracted_pallet_num.kind_of?(Bignum)
    if !extracted_pallet_num.upcase.include?("INVALID")
      @scratch_pad["pallet_number"] = extracted_pallet_num
      return nil
    else
      return extracted_pallet_num
    end
  end
end
