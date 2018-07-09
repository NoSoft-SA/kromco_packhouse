class ScanBinOnTrip < PDTTransactionState

  def initialize(parent)
    @parent = parent
  end

  def bin_on_active_trip?(bin_no, delivery_id)
        query = "select vehicle_jobs.vehicle_job_number from bins, vehicle_jobs,vehicle_job_units where bins.bin_number = vehicle_job_units.unit_reference_id and vehicle_job_units.vehicle_job_id = vehicle_jobs.id and vehicle_jobs.date_time_offloaded is null and
                bins.bin_number = '#{bin_no}'"
        jobs = VehicleJob.find_by_sql(query)

        #rule is that a bin can exist on another tripsheet ONLY IF the other tripsheet id a delivery that is not yet done(accepted at complex)
        if  delivery_id
            uncompleted_delivery_query = "SELECT
                                        delivery_route_steps.id
                                         FROM
                                         public.delivery_route_steps
                                         WHERE
                                        delivery_route_steps.delivery_id = #{delivery_id.to_s} AND
                                        delivery_route_steps.route_step_code = 'accepted_at_complex' AND
                                        delivery_route_steps.date_completed IS NULL  "


             uncompleted_delivery = DeliveryRouteStep.find_by_sql(uncompleted_delivery_query)

             if  uncompleted_delivery.length() > 0
                return nil
             end
         end


        if jobs.length() > 0
          return jobs[0].vehicle_job_number
        else
          return nil
        end

  end



  def build_default_screen
    transaction_types = ["", "delivery"].map { |s| s }.join(",")
    transaction_types = ", ," + transaction_types

    field_configs     = Array.new


    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"tripsheet", :value=>@parent.tripsheet_number}
    key_in_bin_number = authorise_scan("2.2.4",'key_in_bin_number',ActiveRequest.get_active_request.user)
    if key_in_bin_number
      field_configs[field_configs.length]   = {:type=>"text_box", :name=>"bin_number", :is_required=>"true", :scan_only=>"false"}
    else
      field_configs[field_configs.length]   = {:type=>"text_box", :name=>"bin_number", :is_required=>"true", :scan_only=>"true"}
    end
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"bins_scanned", :value=>@parent.scanned_bins.length().to_s}

    screen_attributes  = {:auto_submit=>"true",:auto_submit_to=>"bin_scanned", :content_header_caption=>"scan bins on tripsheet",:cache_screen => true}
    buttons = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"bin_scanned", "B1Label"=>"scan_bin", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins  = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def
  end

  def create_tripsheet
    build_default_screen
  end

  def print_tripsheet
    question  = "Are you sure you want to print tripsheet??"
    field_configs                         = Array.new
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"tripsheet", :value=>@parent.tripsheet_number}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"bins_scanned", :value=>@parent.scanned_bins.length().to_s}
    field_configs[field_configs.length()] = {:type=>"drop_down", :name=>"destination_location", :is_required=>"true", :list => ",CDE Floor,1-5 Floor,Packhouse,Reworks", :is_required=>"true"}
    field_configs[field_configs.length]   = {:type=>"text_box", :name=>"printer", :is_required=>"false"}
    field_configs[field_configs.length()] = {:type=>"text_line", :name=>"question", :value=>question}

    screen_attributes                     = {:auto_submit=>"false", :content_header_caption=>"print tripsheet"}
    buttons                               = {"B3Label"=>"", "B2Label"=>"no", "B1Submit"=>"yes", "B1Label"=>"yes", "B1Enable"=>"true", "B2Enable"=>"true", "B3Enable"=>"false"}
    plugins                               = nil
    result_screen_def                     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def 
  end


  def bin_scanned


    if (error = valid_bin?) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(error, nil, nil, nil)
      return result_screen
    end
    @parent.scanned_bins.push(@bin_number)
    return build_default_screen
  end


  def valid_bin_for_delivery? (delivery_id)
    if self.parent.transaction_type == "delivery"
      #set the delivery process vars if this is the very first bin
      delivery = nil
      error = nil
      error = ["bin does not belong to any delivery"] if !delivery_id
      return error  if error

      if self.parent.delivery_number == ""
        delivery                    = Delivery.find(delivery_id)
        self.parent.delivery_number = delivery.delivery_number
        self.parent.delivery_id     = delivery.id
        return nil
      else
        #make sure that scanned bin belongs to process's delivery
        if delivery_id != self.parent.delivery_id
          return ["bin does not belong to delivery: " + self.parent.delivery_number]
        else
          return nil
        end

      end
    else
      return nil
    end

  end


  def valid_bin?
    bin_number_entered = self.pdt_screen_def.get_control_value("bin_number")
    bin_record         = Bin.find_by_sql("select * from bins where bins.bin_number = '#{bin_number_entered}' ")[0]

    if bin_record==nil
      error = ["bin number :'#{bin_number_entered}' does not exist"]
      return error
    end


    trip = nil
    if trip = bin_on_active_trip?(bin_number_entered,bin_record.delivery_id)
      return  error = ["bin number :'#{bin_number_entered}' already on trip: ",trip]
    end


    production_run_tipped = bin_record.production_run_tipped_id

    if production_run_tipped != nil
      error = ["Bin already  tipped "]
      return error
    end
    if bin_record == nil
      error = ["Bin number does not exist"]
      return error
    end

    @bin_number = bin_record.bin_number
    if @parent.scanned_bins.include?(@bin_number)
      error = [" Bin number :'#{@bin_number}' has been scanned already"]
      return error
    end

    stocks_record = StockItem.find_by_inventory_reference(bin_number_entered)
    if stocks_record == nil
      error = ["Bin not in stock"]
      return error
    end

    bin_location=ActiveRecord::Base.connection.select_one("select locations.location_barcode,locations.location_code from locations
                                                          join stock_items on stock_items.location_id=locations.id
                                                          join bins on stock_items.inventory_reference=bins.bin_number
                                                          where bins.bin_number='#{bin_record.bin_number}'")
    if !bin_location.empty?
      location_bar_code =bin_location['location_barcode']
      location_code =bin_location['location_code']
      location_status =  check_location_status(location_bar_code)
        if  location_status  != nil
            error = ["Bin is in location #{location_code}.Status is: SEALED "]
             return error
        end
    end


    exit_reference = bin_record.exit_ref
    if exit_reference != nil
      error = ["bin :'#{bin_record.exit_ref}'"]
      return error
    end

    rw_receipt_bin = RwActiveBin.find_by_sql("select * from rw_active_bins where bin_number = '#{@bin_number.to_s}' order by id desc")
    if !rw_receipt_bin.empty?
      error= ["Bin number :'#{bin_number_entered}' is in reworks "]
      return error
    end
    return nil
  end

  def check_location_status(location_barcode)
      location_status= Location.find_by_sql("select locations.location_status from locations
                                            where location_barcode='#{location_barcode}'  ")
      if !location_status.empty?
        location_status=location_status[0].location_status
        if location_status && location_status.upcase.index("SEALED")
           return  location_barcode
        else
          return nil
        end
      else
        return nil
      end
    end

  def build_bin_removal_screen
    field_configs = Array.new
    field_configs[field_configs.length()] = {:type=>"static_text",:name=>"bins_scanned",:value=>@parent.scanned_bins.length().to_s}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"bin_number_to_be_removed",:is_required=>"true"}

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"Remove Bin on Tripsheet"}
    buttons = {"B3Label"=>"" ,"B2Label"=>"","B1Submit"=>"bin_remove","B1Label"=>"remove_bin","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
   return result_screen_def
    end

  def remove_bin
    build_bin_removal_screen
  end

  def bin_remove
    bin_number_entered = self.pdt_screen_def.get_control_value("bin_number_to_be_removed").strip
   if !self.parent.scanned_bins.include?(bin_number_entered)
     return PDTTransaction.build_msg_screen_definition("bin number does not exists ",nil,nil,nil)
   else
     if self.parent.scanned_bins[0] == bin_number_entered 
       return  PDTTransaction.build_msg_screen_definition("Cannot delete the first bin number  ",nil,nil,nil)
     else
       self.parent.scanned_bins.delete(bin_number_entered)
       build_default_screen
     end
    end
  end


  def send_tripsheet_to_printer(vehicle_job, printer)

      out_file_type = "PDF"
      out_file_name = "vehicle_job_#{Time.now.strftime("%m_%d_%Y_%H_%M_%S")}"
      out_file_path = Globals.jasper_reports_pdf_downloads + "/#{out_file_name}"

      err = JasperReports.generate_report('vehicle_job',self.pdt_screen_def.user,{:vehicle_job_number=>vehicle_job.vehicle_job_number,:printer=>printer.system_name,:MODE=>"PRINT",
                                                                                  :OUT_FILE_NAME=>out_file_path,:OUT_FILE_TYPE=>out_file_type, :keep_file=>true})
      if(!err)

          # create vehicle_job_statuses record
          vehicle_job_status = VehicleJobStatus.new
          vehicle_job_status.vehicle_job_number = vehicle_job.vehicle_job_number
          vehicle_job_status.vehicle_job_id = vehicle_job.id
          vehicle_job_status.tripsheet_status_code = "printed"
          vehicle_job_status.create()

          return result = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["Tripsheet was printed successfully!"])

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

  end


  def print_confirmed

    printer_friendly_name = self.pdt_screen_def.get_input_control_value("printer")
    if(!(printer = Printer.find_by_friendly_name(printer_friendly_name)))
      printer_error_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["Printer[#{printer_friendly_name}] not found"])
      return printer_error_screen
    end

    vehicle_jobs = nil
    ActiveRecord::Base.transaction do
      veh_job_type                      = VehicleJobType.find_by_sql("select * from vehicle_job_types  where vehicle_job_types.vehicle_job_type_code = 'BINS' order by vehicle_job_types.id desc")[0]
      vehicle_job_type_id               = veh_job_type.id
      vehicle_jobs                      = VehicleJob.new
      vehicle_jobs.date_time_loaded = Time.now
      vehicle_jobs.vehicle_job_number = @parent.tripsheet_number
      vehicle_jobs.vehicle_job_types_id = vehicle_job_type_id
      first_scanned_stock_item = StockItem.find_by_inventory_reference(@parent.scanned_bins[0])
      vehicle_jobs.created_at_location = first_scanned_stock_item.location_code if(first_scanned_stock_item)
      vehicle_jobs.created_by = @parent.pdt_screen_def.user
      vehicle_jobs.planned_location = self.pdt_screen_def.get_input_control_value("destination_location")

      vehicle_jobs.create

      for bin_number in @parent.scanned_bins
        vehicle_job_unit                   = VehicleJobUnit.new
        vehicle_job_unit.unit_reference_id = bin_number
        vehicle_job_unit.date_time_loaded  = Time.now()
        vehicle_job_unit.vehicle_job_id    = vehicle_jobs.id
        vehicle_job_unit.create
      end

      Inventory.move_stock("Create_Tripsheet", @parent.tripsheet_number, "IN_TRANSIT", @parent.scanned_bins)
    end

    if printer_friendly_name && printer_friendly_name.strip != ""
      return  send_tripsheet_to_printer(vehicle_jobs, printer)
    else
      result        = ["Tripsheet created. You can print with Web App "]
      return  PDTTransaction.build_msg_screen_definition(nil, nil, nil, result)
    end

    self.parent.set_transaction_complete_flag
    return print_result_screen
  end

  def yes
    print_confirmed
  end

  def print_cancelled
    build_default_screen
  end

  def no
    print_cancelled
  end

  def build_bins_list_screen(bins_list, caption, menu_item)
    field_configs = Array.new
    bins_list.each do |bin_num|
      field_configs[field_configs.length] = {:name=>'bin_number', :type=>'text_line', :value=>bin_num.to_s, :is_required=>'true'}
    end
    buttons           = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=> caption, :auto_submit=>"false", :current_menu_item=>menu_item}
    plugins           =nil
    result_screen     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
  end


  def view_bins_on_tripsheet
    list = get_scanned_bins()
    return build_bins_list_screen(list, "Current Bins Scanned On Tripsheet", "2.2.4.4")
  end

  def get_scanned_bins
    scanned_list = self.parent.scanned_bins
    return scanned_list
  end


  def scan_bins_on_tripsheet
    build_default_screen
  end


end
