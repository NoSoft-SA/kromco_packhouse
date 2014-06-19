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
   @printer = self.pdt_screen_def.get_input_control_value("printer")
   vehicle_job = VehicleJob.find_by_vehicle_job_number(@vehicle_job_no)
   if vehicle_job
      http_conn = Net::HTTP.new(Globals.get_crystal_reports_server_ip, Globals.get_crystal_reports_server_port)
      report_parameters = "vehicle_job_number=" + vehicle_job.vehicle_job_number.to_s + "&reference_type=vehicle_jobs&reference_id=6&report_type=Tripsheet_IW&printer_name=" + @printer.to_s + "&report_user_ref=" + vehicle_job.id.to_s
      response = http_conn.request_get(Globals.get_crystal_reports_server + report_parameters)
      puts "Body : " + response.body.to_s
      puts "Response : " + response.to_s
      if response.body.to_s.strip == ""
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
        error_msg = response.body.to_s.gsub("<error>", "").gsub("</error>","").gsub("<![CDATA[","").gsub("]]>","")
        errors_array = error_msg.split(". ")
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