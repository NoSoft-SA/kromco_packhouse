class BinScanning < PDTTransactionState

  def initialize(parent)
    @parent = parent
       self.parent.set_cannot_cancel
  end

  def is_next_bin_sample_bin?

    @sample_bins_sequences = self.parent.sample_bins_sequences #=> sample_bin_sequences is an array
    if  @sample_bins_sequences.include?((self.parent.full_bins.length().to_i + self.parent.half_bins.length().to_i + 1))
      return true
    else
      return false
    end

  end

  def build_default_screen

    field_configs                         = Array.new
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"delivery_number", :value=>@parent.delivery_number.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"rmt_variety", :value=>@parent.delivery_rmt_variety.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"full_bins_scanned", :value=>self.parent.full_bins.length().to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"half_bins_scanned", :value=>self.parent.half_bins.length().to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"track_slms_indicator", :value=>@parent.track_slms_indicator_code}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"sample_bins_scanned", :value=>self.parent.sample_bins.length().to_s}
    key_in_bin_number = authorise_scan("2.1.1",'key_in_bin_number',ActiveRequest.get_active_request.user)
    if key_in_bin_number
      field_configs[field_configs.length]   = {:type=>"text_box", :name=>"bin_number", :is_required=>"true", :scan_only=>"false",:scan_field => true}
    else
      field_configs[field_configs.length]   = {:type=>"text_box", :name=>"bin_number", :is_required=>"true", :scan_only=>"true",:scan_field => true}
    end
    statement                             = "Please Apply Sticker"

    if is_next_bin_sample_bin? == true
      field_configs[field_configs.length] = {:type=>"static_text", :name=>"sample_bin", :value=>statement}
    end

    if @parent.active_scan_prompt.include?("full_bins")
      caption = "Scan Full Bins"
    else
      caption = "Scan Half Bins"
    end

    screen_attributes = {:auto_submit=>"true", :auto_submit_to=>"scan_bin_submit", :content_header_caption=>caption.to_s,:cache_screen => true}
    buttons           = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"scan_bin_submit", "B1Label"=>"scan_bins", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins           = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def
  end

  def validate_input
    scan_bin_number  = self.parent.pdt_screen_def.get_control_value("bin_number")

    bin_ticket_range = BinTicket.find_by_sql("select * from bin_tickets where  '#{scan_bin_number.to_i}' >= cast(bin_tickets.ticket_number_from as bigint) and '#{scan_bin_number.to_i}' <= cast (bin_tickets.ticket_number_to as bigint)  order by bin_tickets.id ")[0]
    if bin_ticket_range == nil
      error = ["Bin ticket does not exist for bin number :" + scan_bin_number]
      return error
    end
    fcast_variety_indicator_id = bin_ticket_range.forecast_variety_indicator_id
    forecast_variety           = ForecastVarietyIndicator.find_by_sql("select * from  forecast_variety_indicators where forecast_variety_indicators.id = '#{fcast_variety_indicator_id}' order by forecast_variety_indicators.id desc ")[0]
    if forecast_variety == nil
      error = ["could not find forecast variety indicator with id :" + fcast_variety_indicator_id.to_s]
      return error
    end

    forecast_farm = forecast_variety.forecast_variety.forecast.farm_code
    if  forecast_farm != self.parent.farm_code
      error = ["delivery is for farm: " + self.parent.farm_code, "This bin ticket is from farm: " + forecast_farm]
      return error
    end


    track_slms_id     = forecast_variety.track_slms_indicator_id

    slms_indicator    = TrackSlmsIndicator.find(track_slms_id)
    slms_indicator_id = slms_indicator.id

    if(forecast_variety.forecast_variety.rmt_variety_code != @parent.delivery_rmt_variety)
      error = ["The forecast rmt_variety_code[#{forecast_variety.forecast_variety.rmt_variety_code}] is not the same as the delivery[#{@parent.delivery_rmt_variety}]"]
      return error
    end

    # if (slms_indicator_id.to_i == @parent.track_slms_indicator_id.to_i)
      @parent.bin_number = scan_bin_number

    # else
    #   error = ["The delivery expects Fruit Type :'#{@parent.track_slms_indicator_code}' but this bin is of type :'#{slms_indicator.track_slms_indicator_code}' "]
    #   return error
    # end
    #================================================================================

#    #CHECK IF route step 'intake' bin scanning complete' IS DONE, RETURN
#    #'bin scanning has been completed' if so'
#    #================================================================================
      check_bin_num = @parent.scan.check(@parent.bin_number)
      if check_bin_num  != nil
        if  (@parent.bin_number ==check_bin_num)
          error = ["Bin number already  exists in bins table "]
          return error
       end
      end

    delivery_route_steps = DeliveryRouteStep.find_by_sql("select *  from  delivery_route_steps  where delivery_id = '#{ @parent.delivery_id }' and route_step_code='intake_bin_scanning'  ")
    route_step_date_1    = delivery_route_steps[0].date_completed

    if route_step_date_1 != nil
      error = ["Bin scan has already completed successfully"]
      return error
    end


    if  (@parent.full_bins.include?(scan_bin_number) || @parent.half_bins.include?(scan_bin_number))
      error = ["Bin number already been scanned"]
      return error
    end

    return nil
  end





  def scan_bin_submit
    if (error = validate_input) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(error, nil, nil, nil)
      return result_screen
    end
    if (txt =change_mode) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(txt, nil, nil, nil)
      return result_screen
    end


     if is_next_bin_sample_bin? == true
      self.parent.sample_bins.push(@parent.bin_number)
     end

    self.parent.active_bins_list.push(@parent.bin_number)

   result = all_bins_scanned?
    if    result== true
      @parent.complete_bin_scan_trans()
    elsif  result != nil
      result_screen = PDTTransaction.build_msg_screen_definition(result, nil, nil, nil)
      return result_screen
    else

      return build_default_screen
    end
  end

  def change_mode
    current_mode =@parent.active_scan_prompt
    msg          = @parent.check_mode(@parent.active_scan_prompt)
    if    msg != true
      return msg
    end
    new_mode =@parent.active_scan_prompt
    if current_mode != new_mode
      result = @parent.change_mode_prompt(current_mode, new_mode)
      return result
    end
    return nil

  end

  def all_bins_scanned?
    if  (self.parent.full_bins.length()==self.parent.qty_full_bins_required && parent.half_bins.length() == self.parent.qty_half_bins_required)
      return true
    else
      result = change_mode
    end
  end

  def scan_full_bins
    output = @parent.check_mode("full_bins")
    if    (output == nil || output == true)
      build_default_screen
    elsif  output != nil
      result_screen = PDTTransaction.build_msg_screen_definition(output, nil, nil, nil)
      return result_screen
    end

  end

  def scan_half_bins
    output = @parent.check_mode("half_bins")
    if   (output == nil || output == true)
      build_default_screen
    elsif  output != nil
      result_screen = PDTTransaction.build_msg_screen_definition(output, nil, nil, nil)
      return result_screen
    end

  end

  def yes
    complete_confirmed
  end

  def no
    complete_cancelled
  end


  def permission?
    if (self.parent.pdt_method.method_name.to_s == "complete_delivery")
      return "yes"
    end
    return nil
  end

  def complete_delivery

    outputs = ["Finished bin scanning for delivery = " + self.parent.delivery_number.to_s,
               "sample bins : " + self.parent.sample_bins.length().to_s,
               "full bins scanned : " + self.parent.full_bins.length().to_s,
               "half bins scanned : " + self.parent.half_bins.length().to_s,
               "Are you sure you want to complete the delivery transaction?", nil, nil]
    return self.parent.build_choice_screen(outputs)
  end

  def complete_confirmed
    deliveries = Delivery.find_by_delivery_number(@parent.delivery_number)

    n_partial  = deliveries.quantity_partial_units
    n_full     = deliveries.quantity_full_bins
    n_partial = 0 if !n_partial
    n_full = 0 if !n_full


    if (n_partial == @parent.qty_half_bins_required && n_full == @parent.qty_full_bins_required)
      self.parent.complete_bin_scan_trans
    else
      return PDTTransaction.build_msg_screen_definition(nil, nil, nil, "Required full bins :'#{self.parent.qty_full_bins_required.to_s}' and half bins :'#{self.parent.qty_half_bins_required.to_s}'have not been scanned, To force an early complete inform the supervisor")
    end
  end

  def complete_cancelled
    build_default_screen
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

  def view_full_bins_scanned
    list = get_scanned_full_bins()
    return build_bins_list_screen(list, "Current Full Bins Scanned ", "2.1.1.5")
  end

  def get_scanned_full_bins
    full_bins =Array.new
    self.parent.full_bins.each { |b| full_bins << b }
    return full_bins
  end

  def view_half_bins_scanned
    list = get_scanned_half_bins()
    return build_bins_list_screen(list, "Current Half Bins Scanned ", "2.1.1.6")
  end

  def get_scanned_half_bins
    half_bins =Array.new
    self.parent.half_bins.each { |b| half_bins << b }
    return half_bins
  end

  #20100316529375

  def view_sample_bins_scanned
    list = get_scanned_sample_bins()
    return build_bins_list_screen(list, "Current Sample Bins Scanned ", "2.1.1.7")
  end

  def get_scanned_sample_bins
    sample_bins =Array.new
    self.parent.sample_bins.each { |b| sample_bins << b }
    return sample_bins
  end

  def scan_intake_bins
    build_default_screen
  end

end
