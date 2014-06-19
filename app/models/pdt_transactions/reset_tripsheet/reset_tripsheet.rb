class ResetTripsheet <PDTTransaction

  def reset_tripsheet
    build_default_screen
  end

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"vehicle_job_no",:label=>"tripsheet",:is_required=>"true"}

    buttons = {:B1Label=>"Submit",:B1Enable=>"true",:B1Submit=>"reset_tripsheet_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"reset tripsheet",:auto_submit=>"false"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end
  
  def reset_tripsheet_submit
    tripsheet = VehicleJob.find_by_vehicle_job_number(self.pdt_screen_def.get_input_control_value("vehicle_job_no"))
    set_temp_record("tripsheet", tripsheet)

    if @scratch_pad["tripsheet"] == nil
      additonal_lines_array = ["Tripsheet not found!!!!"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
      return result_screen
    end

    if cancelled?
      additonal_lines_array = ["Tripsheet already cancelled"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
      return result_screen
    end

    if offloaded?
      additonal_lines_array = ["Tripsheet already offloaded"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
      return result_screen
    end

    reset_trans
  end

  def cancelled?
    if @scratch_pad["tripsheet"].cancel_boolean != nil && @scratch_pad["tripsheet"].cancel_boolean.to_s == "true"
      return true
    else
      return false
    end
  end

  def offloaded?
    if @scratch_pad["tripsheet"].date_time_offloaded != nil 
      return true
    else
      return false
    end
  end

  def reset_trans
    ActiveRecord::Base.transaction do
      vehicle_job_units = @scratch_pad["tripsheet"].vehicle_job_units
      @scratch_pad["tripsheet"].update_attribute(:cancel_boolean, true)
      vehicle = Vehicle.find(@scratch_pad["tripsheet"].vehicle_id)
      vehicle.in_use = false
      vehicle.save!

      #stock_item_references = Array.new  TODO STOCK DEACTIVATED

      for unit in vehicle_job_units
        unit.update_attribute(:cancel_date, Time.now.strftime("%Y/%m/%d/%H:%M:%S"))
        #stock_item_references.push(unit.unit_reference_id)
      end
      #HOW TO GET THE REPORT BELONGING TO THIS TRIPSHEET
      #--------------------------------
      #  Confirm query to be executed
      #--------------------------------
      report = Report.find_by_sql("select * from reports where reference_type='vehicle_jobs' and report_user_ref='#{@scratch_pad["tripsheet"].id}' order by version_number desc")[0]
      if report != nil
        report.update_attribute(:cancelled_on, Time.now.strftime("%Y/%m/%d/%H:%M:%S"))
      end
      #message = Inventory.undo_move_stock(stock_item_references,"reset_tripsheet",@scratch_pad["tripsheet"].vehicle_job_number)
     

        self.set_transaction_complete_flag
        msg = nil
        additonal_lines_array = ["Tripsheet has been reset"]
        result_screen = PDTTransaction.build_msg_screen_definition(msg,nil,nil,additonal_lines_array)
        return result_screen
    end
    
  end
end