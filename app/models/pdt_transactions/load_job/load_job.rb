# To change this template, choose Tools | Templates
# and open the template in the editor.

class LoadJob < PDTTransaction
  def build_default_screen
    field_configs = Array.new
      field_configs[field_configs.length] = {:name=>'location',:type=>'text_box',:label=>'scan tunnel',:is_required=>'true'}

    buttons = {:B1Label=>"Submit",:B1Enable=>"false",:B1Submit=>"load_job_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"scan tunnel",:auto_submit=>"true",:auto_submit_to=>"load_job_submit"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end

  def load_job
    build_default_screen
  end

#  def location_exists?
#    if sel
#      return true
#    end
#
#    return false
#  end

  def load_job_submit
    location = Location.find_by_location_barcode(self.pdt_screen_def.get_input_control_value("location"))
    self.set_temp_record(:location, location)
    if !location
      result_screen = PDTTransaction.build_msg_screen_definition("location does not exist",nil,nil,nil)
      return result_screen
    end

    if !location.current_job_reference_id
      result_screen = PDTTransaction.build_msg_screen_definition("job not created , create new job",nil,nil,nil)
      return result_screen
    end
    job = Job.find_by_id(location.current_job_reference_id)
    
    if !job
      result_screen = PDTTransaction.build_msg_screen_definition("job not created , create new job",nil,nil,nil)
      return result_screen
    end

    if job.job_type_code.upcase != "RECOOLING"
      result_screen = PDTTransaction.build_msg_screen_definition("this is not a recooling job",nil,nil,nil)
      return result_screen
    end

    if job.current_job_status.upcase != "JOB_CREATED"
      result_screen = PDTTransaction.build_msg_screen_definition("job[" + job.job_number + "] status must be 'created'",nil,nil,nil)
      return result_screen
    end

    pallet_probes = PalletProbe.find_all_by_job_id(job.id)
    if (pallet_probes.length() == 0)
      error = ["NO PROBES ALLOCATED"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
      return result_screen
    end

    ActiveRecord::Base.transaction do
      job.update_attribute(:current_job_status, "JOB_LOADED")

      self.set_transaction_complete_flag
    end

     self.set_transaction_complete_flag
     result_screen = PDTTransaction.build_msg_screen_definition("job loaded succesfully",nil,nil,nil)
     return result_screen
  end
end
