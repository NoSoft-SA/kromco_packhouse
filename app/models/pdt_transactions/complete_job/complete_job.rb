class CompleteJob < PDTTransaction

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"location_barcode", :is_required=>"true", :scan_field => true, :submit_form => true}

    buttons = {"B1Label"=>"submit", "B1Enable"=>"false", "B1Submit"=>"complete_job_submit", "B2Label"=>"", "B2Enable"=>"false", "B3Submit"=>"", "B3Enable"=>"false"}
    screen_attributes = {:content_header_caption=>"complete job", :auto_submit=>"true",:auto_submit_to=>"complete_job_submit"}
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

  def complete_job
    build_default_screen
  end

  def validate_input

    location_barcode_scan = self.pdt_screen_def.get_input_control_value("location_barcode")
    #if scanned_pallet.kind_of?(Fixnum) || scanned_pallet.kind_of?(Bignum)

    location = Location.find_by_location_barcode(location_barcode_scan)


    self.set_temp_record("location", location)

    if (location == nil)
      return ["NO  LOCATION FOR SCAN : "+location_barcode_scan.to_s]
    end

    if (location.current_job_reference_id == nil)
      return ["NO JOB FOR LOCATION"]

    end

    job  = Job.find_by_id(location.current_job_reference_id)


    self.set_temp_record("job", job)
    job_code = job.job_type_code.to_s

    if (job_code.to_s != "recooling")
      return ["NO RECOOLING JOB FOR LOCATION"]
    end

    if (job.current_job_status.upcase != "JOB_LOADED")
      return ["JOB IS NOT LOADED BUT , "+job.current_job_status]
    end


    return nil
  end

  def complete_job_submit
    if (error = validate_input) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
      return result_screen
    else
      complete_job_trans
    end
  end

  def complete_job_trans


    ActiveRecord::Base.transaction do
      job = self.get_temp_record("job")
      job.current_job_status = "JOB COMPLETED"
      job.update

      pallet_probes = PalletProbe.find_all_by_job_id(job.id)
      raise "no pallet probes for job #{job.job_number.to_s}" if  pallet_probes.length() == 0

      pallet_probes.each do |p|

        probe = Probe.find_by_id(p.probe_id)

        probe.probe_status_code  = "NOT IN USE"
        probe.current_pallet_reference_id = nil
        probe.update

        location = self.get_temp_record("location")
        location.current_job_reference_id = nil
        location.update

        location_history  = JobLocationHistory.find_by_location_id(location.id)

        location_history.date_time_completed =  Time.now()
        location_history.update

        pallet = Pallet.find_by_id(p.pallet_id)
        pallet.store_type_code = "storage"
        pallet.update

        p.log_to_history
        p.destroy

      end


      self.set_transaction_complete_flag
      #result = ["pallet.carton_quantity_actual = " + pallet.carton_quantity_actual.to_s + "pallet_num = " + pallet.pallet_number.to_s,"operatore = " + self.pdt_screen_def.user.to_s]
      result = ["job completed successfully"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, result)
      return result_screen
    end

  end
end
