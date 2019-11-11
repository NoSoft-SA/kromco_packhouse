class AcceptRmtTripsheet < PDTTransaction
  attr_accessor :location_code, :bins, :tripsheet, :delivery_id, :delivery_number, :transaction_type

  def initialize()
    @bins = Array.new
  end

  def build_default_screen

    transaction_types                     = ["standard_move                         ", "delivery_accept_at_complex", "delivery_arrive_at_complex"].map { |g| g }.join(",")
    transaction_types                     = ",," + transaction_types

    field_configs                         = Array.new
    field_configs[field_configs.length()] = {:type=>"drop_down", :name=>"transaction_type", :is_required=>"false", :list => transaction_types}
    field_configs[field_configs.length]   = {:type=>"text_box", :name=>"tripsheet", :is_required=>"true", :scan_field => true}
    field_configs[field_configs.length]   = {:type=>"text_box", :name=>"location_barcode", :is_required=>"true", :scan_field => true}

    screen_attributes                     = {:auto_submit=>"true", :auto_submit_to=>"trip_sheet_entered", :content_header_caption=>"Accept Tripsheets"}
    buttons                               = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"trip_sheet_entered", "B1Label"=>"submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins                               = nil
    result_screen_def                     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end


  def scan_tripsheet
    build_default_screen
  end

  def complete_prompt
    outputs = ["Scanned bins = " + self.bins.length().to_s,
               " to be transferred to location : " + self.location_code.to_s,
               "Are you sure you want to complete the trip_sheet move?", nil, nil, nil]
    return self.build_choice_screen(outputs)
  end

  def move_confirmed
    ActiveRecord::Base.transaction do
      if self.transaction_type.index("delivery")
        delivery_route_step                = DeliveryRouteStep.find_by_sql("select * from delivery_route_steps where delivery_id = '#{self.delivery_id}' and route_step_code = '#{@new_route_step}' order by id desc ")[0]
        delivery_route_step.date_completed = Time.now()
        delivery_route_step.update

        if self.transaction_type.index("delivery_accept_at_complex")
          vehicle_job = VehicleJob.find(@vehicle_job_id)
          vehicle_job.update_attribute(:date_time_offloaded, Time.now())
        end

      else

        vehicle_job = VehicleJob.find(@vehicle_job_id)
        vehicle_job.update_attribute(:date_time_offloaded, Time.now())

      end

      Inventory.move_stock('rmt_bins_accept_tripsheet', @tripsheet, @location_code, @bins)


      self.set_transaction_complete_flag
      result        = [" All bins have been moved to location :'#{@location_code}'  successfully "]
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, result)
      return result_screen
    end
  end

  def move_cancelled
    return PDTTransaction.build_msg_screen_definition("Transaction has been cancelled", nil, nil, nil)
  end

  def yes
    move_confirmed
  end

  def no
    move_cancelled
  end

  def trip_sheet_entered
    @tripsheet     = self.pdt_screen_def.get_control_value("tripsheet")
    @location_code = self.pdt_screen_def.get_control_value("location")

    if ((error = validate) != nil)
      result_screen =  PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
      return result_screen
    end
    complete_prompt()
  end


def tripsheet_in_std_move?
     trans_type = self.pdt_screen_def.get_control_value("transaction_type")
     if !trans_type.index("delivery")     #i.e is std move
         #rule: cannot accept a delivery in a std move
         delivery = nil
#         if delivery = Delivery.find_by_delivery_number(@tripsheet)
         if delivery = VehicleJob.find_by_vehicle_job_number_and_transaction_business_name(@tripsheet,"INTAKE_DELIVERY")
             @delivery_id = delivery.id
             return ["You cannot do a std move","with a delivery tripsheet"]
         end
     end

  end

  def all_bins_weighed_if_coldstore?(location_type)

    query          = "SELECT
              bins.bin_number
            FROM
              public.bins,
              public.vehicle_jobs,
              public.vehicle_job_units
            WHERE
              vehicle_job_units.vehicle_job_id = vehicle_jobs.id AND
              vehicle_job_units.unit_reference_id = bins.bin_number AND
              (bins.weight IS  NULL  OR
              bins.weight < 1) AND
              vehicle_jobs.vehicle_job_number = '#{@tripsheet}'"


    unweighed_bins = ActiveRecord::Base.connection.select_all(query)

    if location_type == 'COLDSTORE' && unweighed_bins.length() > 0
      err_lines = ['The following bins are unweighed:']
      err_lines += unweighed_bins.map { |b| b['bin_number'] }

      return err_lines
    else
      return nil
    end

  end

  def validate

     if (error = tripsheet_in_std_move?) != nil
      return error
     end

    if (error = valid_process_stage) != nil
      return error
    end

    if (error = valid_location) != nil
      return error
    end

    if (error = valid_trip_sheet?) != nil
      return error
    end

    if (error = check_treatment_code) != nil
      return error
    end

  end

  def check_treatment_code
    query = "SELECT
              bins.bin_number,treatments.treatment_code
              FROM
              public.bins,
              public.vehicle_jobs,
              public.vehicle_job_units,
              public.rmt_products,
              public.treatments
              WHERE
              vehicle_job_units.vehicle_job_id = vehicle_jobs.id AND
              vehicle_job_units.unit_reference_id = bins.bin_number AND
              bins.rmt_product_id=rmt_products.id  AND
              rmt_products.treatment_id=treatments.id  AND
              vehicle_jobs.vehicle_job_number = '#{@tripsheet}'"
   bins = ActiveRecord::Base.connection.select_all(query)
   failed_bins=Array.new
     for bin in bins
        failed_bins << "Error: KRAT IN KWARANTYN" if (bin['treatment_code']=='QFA' ||bin['treatment_code']=='QFS') && !failed_bins.include?("Error: KRAT IN KWARANTYN")
        failed_bins << bin['bin_number'] if (bin['treatment_code']=='QFA'||bin['treatment_code']=='QFS')
     end
    if failed_bins.empty?
           return nil
          else
            return failed_bins
          end
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

  def valid_location
    location_entered = self.pdt_screen_def.get_control_value("location_barcode").strip
    location         = Location.find_by_sql("select * from locations where location_barcode = '#{location_entered}' order by id desc")[0]

    if location == nil
      error = ["Location not found "]
      return error
    end
    @location_code = location.location_code

    location_type  = location.location_type_code
    if self.transaction_type == "delivery_arrive_at_complex"
      unless location_type == "COMPLEX"
        error = ["Location is not complex"]
        return error
      end
    else
      error = all_bins_weighed_if_coldstore?(location_type)
      return error if error
    end

    if self.transaction_type == "delivery_arrive_at_complex"
      destination_complex = Delivery.find_by_sql("select destination_complex from deliveries where delivery_number=#{self.tripsheet}")[0]['destination_complex']
      if destination_complex !=location.location_code
        error =["Location not the destination specified on delivery tripsheet "]
        return error
      else
        return nil
      end
    end


    if location_type.upcase == "STAGING"
      error = Delivery.delivery_mrl_passed_for_tripsheet?(@tripsheet)
      if error
        return error
      else
        return nil
      end
    end

    location_status =  check_location_status(location.location_barcode)
      if  location_status  != nil
          error = ["Bins cannot be moved to location '#{location.location_code}'.Status is: SEALED "]
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

  def storage_rules_passed?
    #==> method needs to be implemented
  end

  def valid_trip_sheet?
    veh_jobs = VehicleJob.find_by_vehicle_job_number(self.pdt_screen_def.get_control_value("tripsheet").strip)
    self.set_temp_record("vehicle_job", veh_jobs)


    if veh_jobs == nil
      error = ["tripsheet not found "]
      return error
    else
      @vehicle_job_id = veh_jobs.id
      if veh_jobs.date_time_offloaded
        error = ["tripsheet already offloaded "]
        return error
      end
    end
    veh_job_units = veh_jobs.vehicle_job_units.map { |s| s.unit_reference_id }
    @bins         = veh_job_units
    return nil
  end



  def valid_process_stage
    trip_sheet_number = self.pdt_screen_def.get_control_value("tripsheet").strip
    vehicle_job       = VehicleJob.find_by_sql("select * from vehicle_jobs where vehicle_job_number = '#{trip_sheet_number}' order by id desc")[0]
    if vehicle_job == nil
      error = ["Invalid tripsheet:'#{trip_sheet_number}' number"]
      return error
    end

    @transaction_type = self.pdt_screen_def.get_control_value("transaction_type").strip

    delivery_number   = vehicle_job.vehicle_job_number.to_i
    deliveries        = Delivery.find_by_sql("select * from deliveries where delivery_number = '#{delivery_number}' order by deliveries.id desc")

    if self.transaction_type.index("delivery")


       if deliveries.empty?
          error = ["No delivery found for tripsheet number:'#{trip_sheet_number}' "]
          return error
       else
        delivery         = deliveries[0]
        @delivery_id     = delivery.id
       end


      if  self.transaction_type == "delivery_accept_at_complex"
        @required_route_step = "sample_bin_weigh_completed"
        @new_route_step      = "accepted_at_complex"

        #check if bin is in one location static method
        error_msg            = Bin.all_bins_of_same_location?(delivery_id)
        return error_msg if error_msg

      else
        @required_route_step = "intake_bin_scanning"
        @new_route_step      = "arrived_at_complex"
      end

      delivery_route    = DeliveryRouteStep.find_by_sql("select * from delivery_route_steps where delivery_route_steps.delivery_id = '#{@delivery_id}' and delivery_route_steps.route_step_code = '#{@required_route_step}'
                               order by delivery_route_steps.id desc")
      route_step_1      = delivery_route[0]
      date_complete_1   = route_step_1.date_completed
      route_step_code_1 = route_step_1.route_step_code
      if date_complete_1 == nil
        error = ["Delivery route step not done for route_step :'#{route_step_code_1}'"]
        return error
      end

    else
      if deliveries.length() > 0 && deliveries[0].delivery_process_at_completion?
        error = ["This tripsheet belongs to a delivery that ", "is ready to be accepted at complex", "Choose the 'delivery' trans type' for such bins"]
        return error if error

      end

    end

    return nil
  end


end
