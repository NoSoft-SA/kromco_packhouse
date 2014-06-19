class RemoveProbe < PDTTransaction

   def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:name=>'probe',:type=>'text_box',:label=>'scan probe',:is_required=>'true'}
    field_configs[field_configs.length] = {:name=>'pallet',:type=>'text_box',:label=>'scan pallet',:is_required=>'true'}

    buttons = {:B1Label=>"Submit",:B1Enable=>"false",:B1Submit=>"remove_probe_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"remove probe",:auto_submit=>"true",:auto_submit_to=>"remove_probe_submit"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
   end

  def remove_probe
   build_default_screen
  end

  def remove_probe_submit
    if(error = validate)
    result_screen = PDTTransaction.build_msg_screen_definition(error,nil,nil,nil)
    return result_screen
    end

    @pallet_num = self.pdt_screen_def.get_control_value("pallet")
    @probe_code = self.pdt_screen_def.get_control_value("probe")


     ActiveRecord::Base.transaction do
#     pallet_probe_record = PalletProbe.find_by_sql("select * from pallet_probes where pallet_number = '#{@pallet_num}' and probe_code = '#{@probe_code}' order by id desc ")[0]
#     pallet_id = get_temp_record(:pallet_probe).pallet_id #pallet_id = pallet_probe_record.pallet_id

#     probe = Probe.find_by_sql("select * from probes where current_pallet_reference_id = '#{pallet_id}' order by id desc")[0]
     get_temp_record(:probe).probe_status_code = "not_in_use"
     get_temp_record(:probe).current_pallet_reference_id = nil
     get_temp_record(:probe).update

#     probe_status_hist = ProbeStatusHistory.new
#     probe_status_hist.probe_status_code = probe.probe_status_code
#     probe_status_hist.probe_id = probe.id
#     probe_status_hist.date_from = Time.now()
#     status = Status.find_by_status_code(probe.probe_status_code)
#     probe_status_hist.status_id = status.id if status
#     probe_status_hist.create

     get_temp_record(:pallet_probe).destroy #pallet_probe_record.destroy

     self.set_transaction_complete_flag
     result = ["Probe successfully removed!!!!  "]
     result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,result)
     return result_screen
   end
  end

   def validate
    if (error = validate_pallet)
      return error
    end
    if (error = validate_job)
      return error
    end

    if (error = validate_pallet_probe)
      return error
    end
   end

  def validate_pallet
    @pallet_num = self.pdt_screen_def.get_control_value("pallet")
    @probe_code = self.pdt_screen_def.get_control_value("probe")
    pallet_record = PalletProbe.find_by_sql("select * from pallet_probes where pallet_number = '#{@pallet_num}' and probe_code = '#{@probe_code}' order by id desc ")[0]

    if pallet_record == nil
      error = ["pallet probe does not exist!!!"]
      return error
    end
    @job_id = pallet_record.job_id
    return nil
  end

  def validate_job
    job_record = Job.find(@job_id)
    job_status = job_record.current_job_status
    if job_status == 'job_completed'
      error = ["Job already completed!"]
      return error
    end

  end

  def validate_pallet_probe
    pallet_probe_record = PalletProbe.find_by_sql("select * from pallet_probes where pallet_number = '#{@pallet_num}' and probe_code = '#{@probe_code}' order by id desc ")[0]
    probe = Probe.find_by_sql("select * from probes where current_pallet_reference_id = '#{pallet_probe_record.pallet_id}' and probe_code = '#{@probe_code}' order by id desc")[0]

    return ["This probe does not belong to this pallet"] if(!pallet_probe_record || !probe)
    
    set_temp_record(:pallet_probe,pallet_probe_record)
    set_temp_record(:probe,probe)
    return nil
  end


end