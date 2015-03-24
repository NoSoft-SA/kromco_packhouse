class PrintTripsheet < PDTTransaction

  attr_accessor :vehicle_job_no, :printer

 #----------------------------------------------
 # builds the default screen for this state
 #----------------------------------------------
 def build_default_screen
   field_configs = Array.new
   field_configs[field_configs.length] = {:type=>"text_box",:name=>"printer",:is_required=>"true"}
   field_configs[field_configs.length] = {:type=>"text_box",:name=>"vehicle_job_no", :value=>@vehicle_job_no.to_s, :is_required=>"true"}

   screen_attributes = {:auto_submit=>"true",:content_header_caption=>"Scan vehicle",:auto_submit_to=>"print_tripsheet_submit"}
   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"print_tripsheet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
   plugins = nil
   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
   
   return result_screen_def
 end

 def print_tripsheet
   if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
     build_default_screen
   else
     print_tripsheet_submit
   end
 end
   
 def print_tripsheet_submit
   @vehicle_job_no = self.pdt_screen_def.get_input_control_value("vehicle_job_no")
   printer_friendly_name = self.pdt_screen_def.get_input_control_value("printer")
   if(!(@printer = Printer.find_by_friendly_name(printer_friendly_name)))
     printer_error_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["Printer[#{printer_friendly_name}] not found"])
     return printer_error_screen
   end

   vehicle_job = VehicleJob.find_by_vehicle_job_number(@vehicle_job_no)
   if vehicle_job
      out_file_type = "PDF"
      out_file_name = "interwarehouse_tripsheet_#{Time.now.strftime("%m_%d_%Y_%H_%M_%S")}"
      out_file_path = Globals.jasper_reports_pdf_downloads + "/#{out_file_name}"
      err = JasperReports.generate_report('interwarehouse_tripsheet',self.pdt_screen_def.user,{:vehicle_job_number=>vehicle_job.vehicle_job_number,:printer=>@printer.system_name,:MODE=>"PRINT",:OUT_FILE_NAME=>out_file_path,:OUT_FILE_TYPE=>out_file_type})

      if(!err)
        ActiveRecord::Base.transaction do
          # create vehicle_job_statuses record
          vehicle_job_status = VehicleJobStatus.new
          vehicle_job_status.vehicle_job_number = @vehicle_job_no
          vehicle_job_status.vehicle_job_id = vehicle_job.id
          vehicle_job_status.tripsheet_status_code = "printed"
          vehicle_job_status.create()
          set_transaction_complete_flag
          return result = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["Tripsheet was printed successifully!"])
        end
       else
        errors_array = [err.gsub("<BR>","")]
        field_configs = Array.new
        errors_array.each do |err_line|
          field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>err_line}
        end
        screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error messages"}
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"print_tripsheet_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
        return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
      end
      return result
     # puts "Printer called!!!!!!!!!!!!!!!" + Globals.get_crystal_reports_server_ip.to_s + ":" + Globals.get_crystal_reports_server_port.to_s + Globals.get_crystal_reports_server.to_s + report_parameters.to_s
   else
     result = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["vehicle job was not found"])
     return result
   end
 end

end