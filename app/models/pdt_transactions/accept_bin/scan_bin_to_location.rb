class ScanBinToLocation < PDTTransactionState
  def initialize(parent)
    @parent = parent
  end

  def build_default_screen
    transaction_types = ["standard_move", "delivery_accept_at_complex"].map { |s| s }.join(",")
    transaction_types = "," + transaction_types

    field_configs     = Array.new
    if self.parent.transaction_type == ""
      field_configs[field_configs.length()] = {:type=>"drop_down", :name=>"transaction_type", :is_required=>"false", :list => transaction_types}
    else
      field_configs[field_configs.length()] = {:type=>"static_text", :name=>"transaction_type", :value=>self.parent.transaction_type}
    end
    key_in_bin_number = authorise_scan("2.2.1",'key_in_bin_number',ActiveRequest.get_active_request.user)
    if key_in_bin_number
      field_configs[field_configs.length]   = {:type=>"text_box", :name=>"bin_number", :is_required=>"true", :scan_only=>"false",:scan_field => true, :submit_form => true}
    else
      field_configs[field_configs.length]   = {:type=>"text_box", :name=>"bin_number", :is_required=>"true", :scan_only=>"true",:scan_field => true, :submit_form => true}
    end
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"scanned_bins", :value=>@parent.scanned_bins.length().to_s}
    if self.parent.transaction_type == "delivery_accept_at_complex"
      field_configs[field_configs.length()] = {:type=>"static_text", :name=>"delivery_number", :value=>self.parent.delivery_number}
    end
    screen_attributes = {:auto_submit=>"true", :auto_submit_to=>"bin_scanned", :content_header_caption=>"bins scanned",:cache_screen=>true}
    buttons           = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"bin_scanned", "B1Label"=>"scan bins", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins           = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def
  end

  def bin_scanned
    if (error = valid_bin?) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
      return result_screen
    end
    @parent.scanned_bins.push(@bin_number) 
    return build_default_screen
  end

  def is_valid_delivery_tripsheet?(delivery_id)

    delivery = nil
    delivery = Delivery.find(delivery_id) if delivery_id
    if  self.parent.transaction_type == ""
      transaction_type = self.parent.pdt_screen_def.get_control_value("transaction_type").strip
      transaction_type = "standard_move" if transaction_type == "standard_move"
      self.parent.transaction_type = transaction_type
    end

    if self.parent.transaction_type == "delivery_accept_at_complex"
      error_ary =Array.new
#      delivery = nil             #change l made
      if self.parent.delivery_number == ""
        self.parent.delivery_id     = delivery_id
        self.parent.delivery_number = delivery.delivery_number
      else
        if delivery_id != self.parent.delivery_id
          error = "Bin does not belong to delivery number : " + self.parent.delivery_number.to_s
          error_ary << error
        end
      end

      destination_complex = Delivery.find_by_sql("select destination_complex from deliveries where id=#{delivery_id}")[0]['destination_complex']
      if destination_complex !=self.parent.location_code
        error ="Location specified not on delivery "
        error_ary << error
      end

      if !error_ary.empty?
        return error_ary
      else
        return nil
      end
    else

      if delivery && delivery.delivery_process_at_completion?
        error = ["This bin belongs to a delivery that ", "is ready to be accepted at complex", "You must choose the 'delivery' trans type' for such bins"]
        return error if error
      elsif delivery && self.parent.location_type_code.upcase == "STAGING"
        error = Delivery.delivery_mrl_passed?(delivery.id)
        if error
          return error
        else
          return nil
        end
      end
    end
  end

  def valid_bin?
    bin_scanned    = self.parent.pdt_screen_def.get_control_value("bin_number").strip
    bin_number_rec = Bin.find_by_bin_number(bin_scanned)
    if bin_number_rec == nil
      error = ["Invalid bin number or bin number does not exist!"]
      return error
    end
    @bin_number = bin_number_rec.bin_number
    if @parent.scanned_bins.include?(@bin_number)
      error = [" Bin number has been scanned already "]
      return error
    end

    on_a_tripsheet=Bin.is_on_tripsheet?(@bin_number)
    if on_a_tripsheet
      error = ["Bin number :'#{@bin_number}' is already  on  tripsheet: #{on_a_tripsheet} "]
      return error
    end

    delivery_id = bin_number_rec.delivery_id

    error       = is_valid_delivery_tripsheet?(delivery_id)
    return error if error

    if self.parent.transaction_type == "standard_move" || self.parent.transaction_type == "delivery_accept_at_complex"
      if parent.location_type_code == 'COLDSTORE' && (bin_number_rec.weight == nil || bin_number_rec.weight < 1)
        return ["bin has weight!"]
      end

    end

    if self.parent.transaction_type == "delivery_accept_at_complex"
      error_msg = Bin.all_bins_of_same_location?(delivery_id)
      return error_msg if error_msg

      delivery_route = DeliveryRouteStep.find_by_sql("select * from delivery_route_steps where delivery_id = '#{delivery_id}' and route_step_code ='sample_bin_weigh_completed' order by id desc")[0]
      date_complete  = delivery_route.date_completed

      if date_complete == nil
        error = ["Sample bins not weighed"]
        return error
      end
      return nil
    end

    if parent.location_type_code == 'STAGING'
       query="select treatments.treatment_code from treatments inner join rmt_products on rmt_products.treatment_id=treatments.id
                      inner join bins on bins.rmt_product_id=rmt_products.id where bins.id=#{bin_number_rec.id}"
       treatment_code = ActiveRecord::Base.connection.select_one(query)
        if treatment_code && !treatment_code.empty?
              treatment_code=treatment_code['treatment_code']
              error = ["Error: KRAT IN KWARANTYN",bin_scanned ]if treatment_code=='QFA' ||treatment_code=='QFS'
              if error
                return error
              else
                return nil
              end
        else
          return nil
        end

    end

    bin_location=ActiveRecord::Base.connection.select_one("select locations.location_code,locations.location_barcode from locations
                                                          join stock_items on stock_items.location_id=locations.id
                                                          join bins on stock_items.inventory_reference=bins.bin_number
                                                          where bins.bin_number='#{@bin_number}'")

    if !bin_location.empty?
      error = nil
     location_bar_code =bin_location['location_barcode']
     location_code =bin_location['location_code']
     location_status =  Location.check_location_status(location_bar_code)
     if  location_status  != nil
       if location_status == "SEALED"
         error = ["Bin is in location #{location_code}. Status is: SEALED "]
       elsif location_status == "GAS"
         error = ["Bin is in location #{location_code}. Status is: GAS "]
       end
       return error
     end
  end
  end

  def build_bins_list_screen(bins_list, caption, menu_item)
    field_configs = Array.new
    bins_list.each do |bin_num|
      field_configs[field_configs.length] = {:name=>'bin_number', :type=>'text_line', :value=>bin_num.to_s, :is_required=>'true'}
    end
    buttons           = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=> caption, :auto_submit=>"false"}
    plugins           =nil
    result_screen     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
  end

  def view_scanned_bins
    list = get_scanned_bins()
    return build_bins_list_screen(list, "Currently Scanned Bins", "2.2.1.3")
  end

  def get_scanned_bins
    scanned_list = self.parent.scanned_bins
    return scanned_list
  end

  def scan_bin
    build_default_screen
  end

  def complete
    outputs = ["Scanned bins = " + self.parent.scanned_bins.length().to_s +
                   " to be transferred to location : " + self.parent.location_code.to_s,
               "Are you sure you want to complete the process?", nil, nil]
    return self.parent.build_choice_screen(outputs)
  end

  def complete_confirmed

    ActiveRecord::Base.transaction do
      if self.parent.transaction_type == "delivery_accept_at_complex"
        delivery_route_step                = DeliveryRouteStep.find_by_sql("select * from delivery_route_steps where delivery_id = '#{self.parent.delivery_id}' and route_step_code = 'accepted_at_complex' order by id desc ")[0]
        delivery_route_step.date_completed = Time.now()
        delivery_route_step.update

        vehicle_job = VehicleJob.find_by_sql("select * from vehicle_jobs where vehicle_jobs.vehicle_job_number = '#{self.parent.delivery_number}'order by vehicle_jobs.id desc ")[0]
        vehicle_job.update_attribute(:date_time_offloaded, Time.now()) if vehicle_job
      end

      Inventory.move_stock('accept_bins', @parent.delivery_number, @parent.location_code, @parent.scanned_bins)
      self.parent.set_transaction_complete_flag
      result        = [" Bins have been moved to location :'#{@parent.location_code}'  successfully "]
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, result)
      return result_screen
    end

  end

  def complete_cancelled
    build_default_screen
  end

  def yes
    complete_confirmed
  end

  def no
    complete_cancelled
  end
end
