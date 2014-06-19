# To change this template, choose Tools | Templates
# and open the template in the editor.

class CreateJob < PDTTransaction

  def build_default_screen
    field_configs = Array.new
      field_configs[field_configs.length] = {:name=>'location',:type=>'text_box',:label=>'scan location',:is_required=>'true'}

    buttons = {:B1Label=>"Submit",:B1Enable=>"false",:B1Submit=>"create_job_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"create a job",:auto_submit=>"true",:auto_submit_to=>"create_job_submit"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end

  def create_job
    build_default_screen
  end

  def create_job_submit
    location = Location.find_by_location_barcode(self.pdt_screen_def.get_input_control_value("location"))
    if !location
      result_screen = PDTTransaction.build_msg_screen_definition("scanned location is invalid",nil,nil,nil)
      return result_screen
    else
      if(location.unavailable)
        result_screen = PDTTransaction.build_msg_screen_definition("location is unavailable",nil,nil,nil)
        return result_screen
      else
        if(location.current_job_reference_id)
          job = Job.find(location.current_job_reference_id)
          if(job.current_job_status.upcase != "JOB_COMPLETED")
            result_screen = PDTTransaction.build_msg_screen_definition("IN USE",nil,nil,nil)
            return result_screen
          end
        end

        ActiveRecord::Base.transaction do
          new_job_num = MesControlFile.next_seq_web(6)
          new_job = Job.new
          new_job.job_number = new_job_num
          new_job.date_created = Time.now.to_formatted_s(:db)
          new_job.job_type_code = "recooling"
          new_job.current_job_status = 'job_created'
          new_job.create

          job_location_history = JobLocationHistory.new
          job_location_history.precool_job_id = new_job.id
          job_location_history.location_id = location.id
          job_location_history.date_time_loaded = Time.now.to_formatted_s(:db)
          job_location_history.create

          location.update_attribute(:current_job_reference_id, new_job.id)
          self.set_transaction_complete_flag
          result_screen = PDTTransaction.build_msg_screen_definition("job created successfully ",nil,nil,nil)
          return result_screen
        end
      end
    end
  end

end
