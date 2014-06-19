# To change this template, choose Tools | Templates
# and open the template in the editor.

class SetPalletRecoolStatus < PDTTransaction
  def build_default_screen
#   cascades1 = {:type=>'replace_control',
#                                  :settings=>{:target_control_name=>'store_type_code',:remote_method=>'pallet_entered',:filter_fields=>'pallet'}}

    field_configs = Array.new
      field_configs[field_configs.length] = {:name=>'pallet',:type=>'text_box',:label=>'scan pallet',:is_required=>'true',
                                             :cascades=>{:type=>'replace_control',
                                                         :settings=>{:target_control_name=>'store_type_code',:remote_method=>'pallet_entered',:filter_fields=>'pallet'}}}
      field_configs[field_configs.length] = {:name=>'store_type_code',:type=>'static_text',:value=> '',:is_required=>'true'}
#      field_configs[field_configs.length] = {:name=>'name_surname',:type=>'static_text',:value=> 'Luks'}

    buttons = {:B1Label=>"Submit",:B1Enable=>"false",:B1Submit=>"set_pallet_recool_status_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"set pallet recool status",:auto_submit=>"true",:auto_submit_to=>"set_pallet_recool_status_submit"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end

  def pallet_entered
    pallet_number = self.params["pallet"].to_s
    self.set_temp_record(:entered_pallet_number, pallet_number)

    if(error = validate_input)
      result_screen = PdtScreenDefinition.gen_ajax_error_xml(error)
      return result_screen
    else
      pallet = Pallet.find_by_pallet_number(pallet_number)
      if(pallet.store_type_code == "storage")
        list = "storage,cold_store"
      else
        list = "cold_store,storage"
      end
      field_configs = {:type=>"drop_down",:name=>'store_type_code',:list=>list}
      #field_configs2 = {:type=>"static_text",:name=>'store_type_code',:value=> pallet.store_type_code}

      return PdtScreenDefinition.gen_controls_list_xml(field_configs)
    end    
  end

  def set_pallet_recool_status
    build_default_screen
  end

  def validate_pallet
    pallet_number = PDTFunctions.extract_pallet_num(self.get_temp_record(:entered_pallet_number))
    if !pallet_number.upcase.include?("INVALID")
      self.set_temp_record(:pallet_number, pallet_number)
    else
      return pallet_number
    end
    return nil
  end

  def validate_input
    if(error = validate_pallet)
      return error
    end

    stock_item = StockItem.find_by_inventory_reference(self.get_temp_record(:pallet_number))
    if !stock_item
      return "STOCK ITEM DOESN'T EXIST"
    end

    location = Location.find_by_location_code(stock_item.location_code)
    if !location
      return "location " +  stock_item.location_code + " not found"
    end
    if location.current_job_reference_id
      return "job in progress"
    end
#    job = Job.find_by_id(location.current_job_reference_id)
#
#    if !job
#      return "job not created , create new job"
#    end
#
#    #if job.current_job_status.upcase != "JOB_LOADED"
#    if job.current_job_status.upcase != "JOB_COMPLETED"
#      return "recooling job in progress"
#    end

  end
  
  def set_pallet_recool_status_submit
    self.set_temp_record(:entered_pallet_number, self.pdt_screen_def.get_input_control_value("pallet"))
    if(error = validate_input)
      result_screen = PDTTransaction.build_msg_screen_definition(error,nil,nil,nil)
      return result_screen
    end


    pallet = Pallet.find_by_pallet_number(self.pdt_screen_def.get_input_control_value("pallet"))
    entered_store_type_code = self.pdt_screen_def.get_input_control_value("store_type_code")
    
    if(entered_store_type_code == nil)
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,["store_type_code cannot be empty","please select and enter pallet number"])
      return result_screen
    elsif(pallet.store_type_code == entered_store_type_code)
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,["you have not change the store_type_code","please  go back and change it"])
      return result_screen
    else
      pallet.update_attribute(:store_type_code, entered_store_type_code)
      self.set_transaction_complete_flag
      result_screen = PDTTransaction.build_msg_screen_definition("pallet recool status was set successfully",nil,nil,nil)
      return result_screen
    end      
  end
end
