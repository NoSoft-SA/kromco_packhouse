class PutAwayBinTripsheet < PDTTransaction
  attr_accessor :location_code, :bins, :tripsheet, :delivery_id, :delivery_number, :valid_locations, :repr_bin_nr

  def build_default_screen
    field_configs = []
    field_configs << {:type => "text_box", :name => "tripsheet", :is_required => "true",:scan_field => true, :submit_form => true}

    screen_attributes = {:auto_submit => "true", :auto_submit_to => "tripsheet_entered", :content_header_caption => "scan tripsheet"}
    buttons = {"B3Label" => "", "B2Label" => "", "B1Submit" => "tripsheet_entered", "B1Label" => "submit", "B1Enable" => "false", "B2Enable" => "false", "B3Enable" => "false"}
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def putaway_bin_tripsheet
    build_default_screen
  end

  def tripsheet_entered
    @delivery_number = self.pdt_screen_def.get_control_value("tripsheet").strip
    if (!(error=valid_tripsheet?))
      #bins = get_tripsheet_bins()
      #repr_bin = @bins[0].to_hash()
      @repr_bin_nr = @bins[0]
      if is_delivery?()
        if same_kind_of_bins?()
          get_valid_locations()
          return build_scan_location_screen()
        else
          err_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ['bins are not of the same spec'])
          return err_screen
        end
      else
        get_valid_locations()
        return build_scan_location_screen()
      end
    else
      err_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
      return err_screen
    end
  end


  def valid_tripsheet?
    veh_job = VehicleJob.find_by_vehicle_job_number(@delivery_number)
    self.set_temp_record("vehicle_job", veh_job)

    if veh_job == nil
      error = ["tripsheet(#{@delivery_number}) not found "]
      return error
    else
      @tripsheet = veh_job.vehicle_job_number
      if veh_job.date_time_offloaded
        error = ["tripsheet already offloaded "]
        return error
      end
    end
    veh_job_units = veh_job.vehicle_job_units.map { |s| s.unit_reference_id }
    @bins = veh_job_units

    if (!(non_bins = VehicleJobUnit.find_by_sql("select bins.bin_number from vehicle_job_units left outer join bins on bins.bin_number=vehicle_job_units.unit_reference_id  where  bins.bin_number is null and  (vehicle_job_units.unit_reference_id='#{veh_job_units.join("' or vehicle_job_units.unit_reference_id='")}') ")).empty?)
      return ["tripsheet is not a bins tripsheet "]
    end

    if (is_delivery?)
      return ["delivery has not yet arrived at complex "] if(DeliveryRouteStep.find_by_sql("select delivery_route_steps.* from delivery_route_steps join deliveries on deliveries.id=delivery_route_steps.delivery_id where deliveries.delivery_number = '#{@tripsheet}' and delivery_route_steps.route_step_code = 'arrived_at_complex' and delivery_route_steps.date_completed is null order by delivery_route_steps.id desc ")[0])
      return ["sample_bin_weighing has not yet been done for delivery "] if(DeliveryRouteStep.find_by_sql("select delivery_route_steps.* from delivery_route_steps join deliveries on deliveries.id=delivery_route_steps.delivery_id where deliveries.delivery_number = '#{@tripsheet}' and delivery_route_steps.route_step_code = 'sample_bin_weigh_completed' and delivery_route_steps.date_completed is null order by delivery_route_steps.id desc ")[0])
    end

    return nil
  end

  def is_delivery?
    if((self.get_temp_record('vehicle_job') && self.get_temp_record('vehicle_job').transaction_business_name.to_s.upcase == 'INTAKE_DELIVERY') || (VehicleJob.find_by_vehicle_job_number(@delivery_number).transaction_business_name.to_s.upcase == 'INTAKE_DELIVERY'))
      return true
    end
  end

  def same_kind_of_bins?
    or_clause = " (bins.bin_number='#{@bins.join("' or bins.bin_number='")}') " if(@bins.length > 0)
    query = "
    select rmt_products.rmt_product_code,
    (select delivery_track_indicators.track_slms_indicator_code
     from delivery_track_indicators
     where delivery_track_indicators.delivery_id = dels.id
     order by id asc
     limit 1) as track_slms_indicator_code
    ,dels.farm_code,bins.destination_process_var
    from bins
    join deliveries as dels on dels.id=bins.delivery_id
    join rmt_products on rmt_products.id=dels.rmt_product_id
    where #{or_clause}
    "
    puts query
    bin_criteria = ActiveRecord::Base.connection.select_all(query).uniq
    if(bin_criteria.length == 1)
      return true
    end
    return false
  end

  def filter_current_location(location_candidates)
    if((tripsheet_locns = VehicleJob.find_by_sql("select stock_items.location_code
          from vehicle_jobs
          join vehicle_job_units on vehicle_job_units.vehicle_job_id=vehicle_jobs.id
          join stock_items on stock_items.inventory_reference=vehicle_job_units.unit_reference_id
          where vehicle_jobs.vehicle_job_number='#{@delivery_number}'
          group by location_code")).length == 1)
      location_candidates.delete_if { |locn| locn['location_code'] == tripsheet_locns[0].location_code }
    end
  end

  #PROPER METHOD NAME?????
  def filter_pre_sort_locations(location_candidates)
    bin = Bin.find_by_bin_number(@repr_bin_nr)
    if bin.destination_process_var.to_s.upcase == 'PRESORT' || bin.destination_process_var.to_s.upcase == 'OCHARD_RUN'
      location_candidates.delete_if { |locn| !locn['location_code'].to_s.include?('RA_6') && !locn['location_code'].to_s.include?('RA_7') }
    end
  end

  #PROPER METHOD NAME?????
  def filter_low_capacity_locations(location_candidates)
    locns = location_candidates.find_all{ |locn| ((locn['units_in_location'].to_i + @bins.length) > (locn['location_maximum_units'].to_i) && (locn['units_in_location'].to_i < locn['location_maximum_units'].to_i)) }
    location_candidates.delete_if { |locn| (locn['units_in_location'].to_i + @bins.length) > (locn['location_maximum_units'].to_i) }
    if(invalid_locations=self.get_temp_record('invalid_locations'))
      invalid_locations += locns
    else
      self.set_temp_record('invalid_locations',locns)
    end

  end

  def filter_unavailable_locations(location_candidates)
    location_candidates.delete_if { |locn| locn['unavailable']=='t' }
  end

  def filter_sealed_locations(location_candidates)
    location_candidates.delete_if { |locn| locn['location_status'].to_s.upcase.include?('SEALED') || locn['location_status'].to_s.upcase.include?('GAS')  }
  end

  def get_valid_locations
    location_candidates = Bin.valid_storage_locations?(@repr_bin_nr)
    filter_current_location(location_candidates)
    filter_pre_sort_locations(location_candidates)
    filter_low_capacity_locations(location_candidates)
    filter_unavailable_locations(location_candidates)
    filter_sealed_locations(location_candidates)
    @valid_locations = location_candidates
  end

  def build_scan_location_screen
    field_configs = []
    if @valid_locations.length() > 0
      field_configs << {:type => "static_text", :name => "PRIORITY", :value => "LOCATION"}
      @valid_locations.each do |locn|
        field_configs << {:type => "static_text", :name => locn['priority'].to_s, :value => "#{locn['location_code']} (#{locn['location_maximum_units'].to_i - locn['units_in_location'].to_i})"}
      end
    else
      if(self.get_temp_record('invalid_locations') && self.get_temp_record('invalid_locations').length == 0)
        field_configs << {:type => "text_line", :name => 'msg', :value => 'No valid storage rules for bin'}
      else
        field_configs << {:type => "text_line", :name => 'msg', :value => 'No storage rules were found'}
      end
    end
    field_configs << {:name => 'scanned_location', :type => 'text_box', :label => 'scan location', :is_required => 'true'}

    if(self.get_temp_record('invalid_locations') && self.get_temp_record('invalid_locations').length > 0)
      field_configs << {:type => "static_text", :name => "PRIORITY", :value => "INVALID LOCATION"}
      self.get_temp_record('invalid_locations').each do |locn|
        field_configs << {:type => "static_text", :name => locn['priority'].to_s, :value => "#{locn['location_code']} (#{locn['location_maximum_units'].to_i - locn['units_in_location'].to_i}) **"}
      end
    end

    screen_attributes = {:auto_submit => "true", :auto_submit_to => "location_scanned", :content_header_caption => "scan valid location"}
    buttons = {"B3Label" => "", "B2Label" => "", "B1Submit" => "location_scanned", "B1Label" => "submit", "B1Enable" => "false", "B2Enable" => "false", "B3Enable" => "false"}
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    return result_screen_def
  end

  def location_scanned
    if(error=valid_scanned_location?)
      return build_force_move_screen(error)
    else
      return putaway_bin_tripsheet_trans
    end
  end

  def build_force_move_screen(errors)
    field_configs = []
    errors.each do |error|
      field_configs << {:name => 'error', :type => 'text_line', :value=>error}
    end

    if(@env.authorise(extract_actual_program_name(@pdt_method.program_name),'can_force_move',self.pdt_screen_def.user))
      field_configs << {:name => 'force_move', :type => 'check_box', :label => 'force move?',
                                                 :cascades=>{:type=>'replace_control',
                                                           :settings=>{:target_control_name=>'scanned_location',:remote_method=>'force_move_selected',:filter_fields=>'force_move'}}}
    end

    field_configs << {:name => 'scanned_location', :type => 'text_box', :label => 'scan other location'}
    screen_attributes = {:auto_submit => "true", :auto_submit_to => "force_move_submit", :content_header_caption => "scan other location"}
    buttons = {"B3Label" => "", "B2Label" => "", "B1Submit" => "force_move_submit", "B1Label" => "submit", "B1Enable" => "true", "B2Enable" => "false", "B3Enable" => "false"}
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    return result_screen_def
  end

  def force_move_selected
    if(self.params[:force_move] == 'true')
      locn = Location.find_by_location_code(@location_code)
      #field_configs = {:name=>'scanned_location', :label=>'scanned location' ,:type=>'static_text',:value=> locn.location_barcode}
      field_configs = {:name=>'scanned_location', :label=>'scanned location' ,:type=>'text_line',:value=> ''}
    else
      field_configs = {:name => 'scanned_location', :type => 'text_box', :label => 'scan other location'}
    end
    return PdtScreenDefinition.gen_controls_list_xml(field_configs)
  end

  def force_move_submit
    if(self.pdt_screen_def.get_control_value("scanned_location").strip != "")
      return location_scanned
    else
      if(self.pdt_screen_def.get_control_value("force_move").strip == "true")
        repr_bin = Bin.find_by_bin_number(@repr_bin_nr)
        track_indicator_rec  = TrackSlmsIndicator.find(repr_bin.track_indicator1_id)
        query = " select locations.location_code,locations.location_maximum_units,locations.units_in_location,locations.location_status,locations.unavailable
                  ,bin_location_setups.priority
                  from locations
                  join bin_location_setups on bin_location_setups.location_id=locations.id
                  where (locations.location_code='#{@location_code}')
                   and ((bin_location_setups.track_slms_indicator_code='ALL' or bin_location_setups.track_slms_indicator_code='#{track_indicator_rec.track_slms_indicator_code}')
                   and (bin_location_setups.farm_code='ALL' or bin_location_setups.farm_code='#{repr_bin.farm.farm_code}')
                   and (bin_location_setups.rmt_variety_code='ALL' or bin_location_setups.rmt_variety_code='#{repr_bin.rmt_product.variety.rmt_variety_code}')
                   and (bin_location_setups.commodity_code='ALL' or bin_location_setups.commodity_code='#{repr_bin.rmt_product.commodity_code}')
                   and (bin_location_setups.assignment_code='ALL' or bin_location_setups.assignment_code='#{repr_bin.destination_process_var}')
                   and (bin_location_setups.size_code='ALL' or bin_location_setups.size_code='#{repr_bin.rmt_product.size_code}')
                   and (bin_location_setups.ripe_point_code='ALL' or bin_location_setups.ripe_point_code='#{repr_bin.rmt_product.ripe_point_code}')
                   and (bin_location_setups.season='ALL' or bin_location_setups.season='#{repr_bin.season_code}')
                   and (bin_location_setups.product_class_code='ALL' or bin_location_setups.product_class_code='#{repr_bin.rmt_product.product_class_code}')
                   and (bin_location_setups.rmt_product_code='ALL' or bin_location_setups.rmt_product_code='#{repr_bin.rmt_product.rmt_product_code}')
                   and (bin_location_setups.rmt_product_type_code='ALL' or bin_location_setups.rmt_product_type_code='#{repr_bin.rmt_product.rmt_product_type_code}')
                   and (bin_location_setups.treatment_code='ALL' or bin_location_setups.treatment_code='#{repr_bin.rmt_product.treatment_code}'))
                  order by bin_location_setups.priority DESC
              "
        if((@valid_locations=ActiveRecord::Base.connection.select_all(query)).length > 0)
          filter_current_location(@valid_locations)
          return build_force_move_screen(["tripsheet bins are already in the scanned location[#{@location_code}] "]) if(@valid_locations.length == 0)
          filter_low_capacity_locations(@valid_locations)
          return build_force_move_screen(["#{@location_code} does not have enough space (#{self.get_temp_record('invalid_locations')[0]['location_maximum_units'].to_i - self.get_temp_record('invalid_locations')[0]['units_in_location'].to_i}) "]) if(@valid_locations.length == 0)
          filter_unavailable_locations(@valid_locations)
          return build_force_move_screen(["scanned location[#{@location_code}] is unavailable"]) if(@valid_locations.length == 0)
          filter_sealed_locations(@valid_locations)
          return build_force_move_screen(["scanned location[#{@location_code}] is sealed or GAS"]) if(@valid_locations.length == 0)
        end
        return putaway_bin_tripsheet_trans
      else
        return build_force_move_screen(self.pdt_screen_def.get_control_value("error"))
      end
    end
  end

  def putaway_bin_tripsheet_trans
    ActiveRecord::Base.transaction do
      if (is_delivery?)
        delivery_route_step                = DeliveryRouteStep.find_by_sql("select delivery_route_steps.* from delivery_route_steps join deliveries on deliveries.id=delivery_route_steps.delivery_id where deliveries.delivery_number = '#{@tripsheet}' and delivery_route_steps.route_step_code = 'accepted_at_complex' order by delivery_route_steps.id desc ")[0]
        delivery_route_step.update_attribute(:date_completed,DateTime.now)
      end

      vehicle_job = VehicleJob.find_by_vehicle_job_number(@tripsheet)
      vehicle_job.update_attribute(:date_time_offloaded, Time.now())
      if(VehicleJobUnit.update_all(ActiveRecord::Base.extend_set_sql_with_request("date_time_offloaded ='#{vehicle_job.date_time_offloaded.to_formatted_s(:db)}'","vehicle_job_units"), "vehicle_job_id = #{vehicle_job.id}") == 0)
        raise "bins could not be offloaded"
      end

      Inventory.move_stock('PUTAWAY_BIN_TRIPSHEET', @tripsheet, @location_code, @bins)

      self.set_repeat_process_flag
    end
  end

  def valid_location?(locn_barcode)
    return ["scanned location barcode[#{locn_barcode}] does not exist"] if(!(scanned_location=Location.find_by_location_barcode(locn_barcode)))
    set_temp_record('looked_up_location',scanned_location)
    nil
  end

  def valid_scanned_location?
    scanned_location_barcode = self.pdt_screen_def.get_control_value("scanned_location").strip

    if(error=valid_location?(scanned_location_barcode))
      return error
    end

    @location_code = get_temp_record('looked_up_location').location_code
    return nil if(@valid_locations.map{|lcn| lcn['location_code']}.include?(@location_code))

    repr_bin = Bin.find_by_bin_number(@repr_bin_nr)
    track_indicator_rec  = TrackSlmsIndicator.find(repr_bin.track_indicator1_id)
    query = " select locations.location_code,locations.location_maximum_units,locations.units_in_location,locations.location_status,locations.unavailable
              ,bin_location_setups.priority
              from locations
              join bin_location_setups on bin_location_setups.location_id=locations.id
              where (locations.location_code='#{@location_code}')
               and ((bin_location_setups.track_slms_indicator_code='ALL' or bin_location_setups.track_slms_indicator_code='#{track_indicator_rec.track_slms_indicator_code}')
               and (bin_location_setups.farm_code='ALL' or bin_location_setups.farm_code='#{repr_bin.farm.farm_code}')
               and (bin_location_setups.rmt_variety_code='ALL' or bin_location_setups.rmt_variety_code='#{repr_bin.rmt_product.variety.rmt_variety_code}')
               and (bin_location_setups.commodity_code='ALL' or bin_location_setups.commodity_code='#{repr_bin.rmt_product.commodity_code}')
               and (bin_location_setups.assignment_code='ALL' or bin_location_setups.assignment_code='#{repr_bin.destination_process_var}')
               and (bin_location_setups.size_code='ALL' or bin_location_setups.size_code='#{repr_bin.rmt_product.size_code}')
               and (bin_location_setups.ripe_point_code='ALL' or bin_location_setups.ripe_point_code='#{repr_bin.rmt_product.ripe_point_code}')
               and (bin_location_setups.season='ALL' or bin_location_setups.season='#{repr_bin.season_code}')
               and (bin_location_setups.product_class_code='ALL' or bin_location_setups.product_class_code='#{repr_bin.rmt_product.product_class_code}')
               and (bin_location_setups.rmt_product_code='ALL' or bin_location_setups.rmt_product_code='#{repr_bin.rmt_product.rmt_product_code}')
               and (bin_location_setups.rmt_product_type_code='ALL' or bin_location_setups.rmt_product_type_code='#{repr_bin.rmt_product.rmt_product_type_code}')
               and (bin_location_setups.treatment_code='ALL' or bin_location_setups.treatment_code='#{repr_bin.rmt_product.treatment_code}'))
              order by bin_location_setups.priority DESC
          "
    if((@valid_locations=ActiveRecord::Base.connection.select_all(query)).length > 0)
      filter_current_location(@valid_locations)
      return ["tripsheet bins are already in the scanned location[#{@location_code}] "] if(@valid_locations.length == 0)
      filter_pre_sort_locations(@valid_locations)
      return ["scanned location[#{@location_code}] is not in RA_6 or RA_7"] if(@valid_locations.length == 0)
      filter_low_capacity_locations(@valid_locations)
      return ["#{@location_code} does not have enough space (#{self.get_temp_record('invalid_locations')[0]['location_maximum_units'].to_i - self.get_temp_record('invalid_locations')[0]['units_in_location'].to_i}) "] if(@valid_locations.length == 0)
      filter_unavailable_locations(@valid_locations)
      return ["scanned location[#{@location_code}] is unavailable"] if(@valid_locations.length == 0)
      filter_sealed_locations(@valid_locations)
      return ["scanned location[#{@location_code}] is sealed or GAS"] if(@valid_locations.length == 0)
    else
      return ["scanned location[#{@location_code}] has not been setup for this kind of tripsheet"]
    end
    return nil
  end

  def valid_bin?(bin)
    bin_number_rec = Bin.find_by_bin_number(bin)
    return ["Invalid bin number or bin number does not exist"] if (!bin_number_rec)
  end

end
