# To change this template, choose Tools | Templates
# and open the template in the editor.

class AssignProbe < PDTTransaction
  def build_default_screen
    field_configs = Array.new
      field_configs[field_configs.length] = {:name=>'probe',:type=>'text_box',:label=>'scan_probe',:is_required=>'true'}
      field_configs[field_configs.length] = {:name=>'pallet',:type=>'text_box',:label=>'scan_pallet',:is_required=>'true'}

    buttons = {:B1Label=>"Submit",:B1Enable=>"false",:B1Submit=>"assign_probe_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"assign probe",:auto_submit=>"true",:auto_submit_to=>"assign_probe_submit"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end

  def assign_probe
    build_default_screen
  end

  def validate_pallet
    pallet_number = PDTFunctions.extract_pallet_num(self.get_temp_record(:scanned_pallet))

    if !pallet_number.upcase.include?("INVALID")
      self.set_temp_record(:pallet_number, pallet_number)
    else
      return pallet_number
    end
   return nil
  end

  def pallet_probe_exist?
    pallet_probe = PalletProbe.find_by_probe_code(self.get_temp_record(:probe_code))

    if pallet_probe
      return pallet_probe.pallet_number
    end

    return nil
  end

  def probe_in_use?
    probe = self.get_temp_record(:probe)
    if(probe.probe_status_code && probe.probe_status_code.to_s.upcase == "IN_USE")
      return true
    end

    return false
  end

  def validate_input
    if(error = validate_pallet)
#      result_screen = PDTTransaction.build_msg_screen_definition(error,nil,nil,nil)
      return error
    end

    pallet = Pallet.find_by_pallet_number(self.get_temp_record(:pallet_number))
    if(!pallet.store_type_code||pallet.store_type_code.upcase == "STORAGE")
#      result_screen = PDTTransaction.build_msg_screen_definition("pallet does not require cooling",nil,nil,nil)
      return "pallet does not require cooling"
    end

    if connected_pallet = pallet_probe_exist?
#      result_screen = PDTTransaction.build_msg_screen_definition("pallet probe doesn't exist",nil,nil,nil)
      return "probe already assigned to pallet " + connected_pallet
    end

    probe = Probe.find_by_probe_code(self.get_temp_record(:probe_code))
    self.set_temp_record(:probe, probe)
    if !probe
      return "probe doesn't exist"
    end

    if probe_in_use?
#        result_screen = PDTTransaction.build_msg_screen_definition("probe in use",nil,nil,nil)
      return "probe in use"
    end

    stock_item = StockItem.find_by_inventory_reference(self.get_temp_record(:pallet_number))#validate?
    if !stock_item
#      result_screen = PDTTransaction.build_msg_screen_definition("STOCK ITEM DOESN'T EXIST",nil,nil,nil)
      return "STOCK ITEM DOESN'T EXIST"
    end

    location = Location.find_by_location_code(stock_item.location_code)
    return "location '#{stock_item.location_code.to_s}' does not exist" if !location
    if !location.current_job_reference_id
#      result_screen = PDTTransaction.build_msg_screen_definition("job not created , create new job",nil,nil,nil)
      return "job not created for pallet location(#{location.location_barcode}), create new job"
    end
    job = Job.find_by_id(location.current_job_reference_id)

    if !job
      return "job not created , create new job"
    end

    self.set_temp_record(:job, job)
    if job.current_job_status.upcase == "JOB_LOADED"
#      result_screen = PDTTransaction.build_msg_screen_definition("job already loaded",nil,nil,nil)
      return "job already loaded"
    elsif(job.current_job_status.upcase == "JOB_COMPLETED")
#      result_screen = PDTTransaction.build_msg_screen_definition("job[" + job.job_number + "] already completed",nil,nil,nil)
      return "job[" + job.job_number + "] already completed"
    end

    if job.current_job_status.upcase != "JOB_CREATED"
#      result_screen = PDTTransaction.build_msg_screen_definition("job[" + job.job_number + "] can only be created",nil,nil,nil)
      return "job[" + job.job_number + "] can only be created"
    end

    return nil
  end

  def assign_probe_submit
    scanned_pallet = self.pdt_screen_def.get_input_control_value("pallet")
    probe_code = self.pdt_screen_def.get_input_control_value("probe")
    self.set_temp_record(:scanned_pallet, scanned_pallet)
    self.set_temp_record(:probe_code, probe_code)

    if(error = validate_input)
      result_screen = PDTTransaction.build_msg_screen_definition(error,nil,nil,nil)
      return result_screen
    end

    ActiveRecord::Base.transaction do
      pallet = Pallet.find_by_pallet_number(self.get_temp_record(:pallet_number))
      probe = self.get_temp_record(:probe)
      job = self.get_temp_record(:job)

      pallet_probes_rec = PalletProbe.new
      pallet_probes_rec.pallet_number = pallet.pallet_number
      pallet_probes_rec.pallet_id = pallet.id
      pallet_probes_rec.probe_code = probe.probe_code
      pallet_probes_rec.probe_id = probe.id
      pallet_probes_rec.job_id = job.id
      pallet_probes_rec.date_from = Time.now.to_formatted_s(:db)
      #pallet_probes_rec.date_to =
      pallet_probes_rec.create


      probe.current_pallet_reference_id = pallet.id
      probe.probe_status_code = "IN USE"
      probe.update

#      probe_status_hist = ProbeStatusHistory.new
#      probe_status_hist.probe_status_code = probe.current_probe_status
#      probe_status_hist.probe_id = probe.id
#      probe_status_hist.date_from = Time.now.to_formatted_s(:db)
#        status =Status.find_by_status_code(probe.current_probe_status)
#      probe_status_hist.status_id = status.id if status
#      probe_status_hist.create
      self.set_transaction_complete_flag
      result_screen = PDTTransaction.build_msg_screen_definition("probe assigned to pallet successfully",nil,nil,nil)
      return result_screen
    end

  end
end
