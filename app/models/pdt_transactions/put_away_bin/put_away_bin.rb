class PutAwayBin < PDTTransaction
  attr_accessor :location_code ,:bins ,:valid_locations

  def initialize
    @bins = []
  end

  def build_default_screen
    field_configs = []
    field_configs << {:type => "static_text", :name => "bins_scanned", :value=>@bins.size} if(!@bins.empty?)
    field_configs << {:type => "text_box", :name => "scanned_bin",:label=>"bin",:is_required => "true"}
    field_configs << {:type => "check_box", :name => "last_scan",:label=>"last_scan?"}
    screen_attributes = {:auto_submit => "true", :auto_submit_to => "bin_scanned", :content_header_caption => "scan bin"}
    buttons = {"B3Label" => "", "B2Label" => "", "B1Submit" => "bin_scanned", "B1Label" => "submit", "B1Enable" => "false", "B2Enable" => "false", "B3Enable" => "false"}
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def putaway_bin
    build_default_screen
  end

  def validate
    if(valid_bin?)
      return ["Invalid bin number: #{@bin}","or bin number does not exist!"]
    end

    if(is_tripsheet_bin?)
      return self.get_temp_record('bins_tripsheets').map{|trps| "bin #{trps['unit_reference_id']} belongs to tripsheet #{trps['vehicle_job_number']}"}
    end

    if(!same_kind_of_bins?())
      return ["bin:#{@bin} is not of the same spec"]
    end
  end

  def valid_bin?
    true if(!Bin.find_by_bin_number(@bin))
  end

  def is_tripsheet_bin?
    or_clause = " (unit_reference_id='#{@bins.join("' or unit_reference_id='")}') and vehicle_jobs.date_time_offloaded is null "
    if((bins_tripsheets=VehicleJobUnit.find(:all,
                                         :select=>"vehicle_job_units.unit_reference_id,vehicle_jobs.vehicle_job_number",
                                         :conditions=>or_clause,
                                         :joins=>"join vehicle_jobs on vehicle_jobs.id=vehicle_job_units.vehicle_job_id")).length > 0)
      self.set_temp_record('bins_tripsheets',bins_tripsheets)
      return true
    end
    return false
  end

  def same_kind_of_bins?
    or_clause = " (bins.bin_number='#{@bins.join("' or bins.bin_number='")}') "
    query = "
    select track_slms_indicators.track_slms_indicator_code,bins.season_code,rmt_products.rmt_product_code
    from bins
    join rmt_products on rmt_products.id=bins.rmt_product_id
    join track_slms_indicators on track_slms_indicators.id=bins.track_indicator1_id
    where #{or_clause}
    group by track_slms_indicators.track_slms_indicator_code,bins.season_code,rmt_products.id
    "
    puts query
    bin_criteria = ActiveRecord::Base.connection.select_all(query).uniq
    if(bin_criteria.length == 1)
      return true
    end
    return false
  end

  def bin_scanned
    @bin = self.pdt_screen_def.get_control_value("scanned_bin").strip
    last_scan = self.pdt_screen_def.get_control_value("last_scan").strip

    @bins.push(@bin) if(!@bins.include?(@bin))
    if(error=validate)
      @bins.pop
      return PDTTransaction.build_msg_screen_definition("valid bins already scanned  #{@bins.length}",nil,nil,error)
    end

    if(last_scan=='true')
      @rep_bin = @bins[0]
      get_valid_locations()
      return build_scan_location_screen()
    else
      build_default_screen
    end
  end

  def filter_current_location(location_candidates)
    bin = StockItem.find_by_inventory_reference(@rep_bin)
    location_candidates.delete_if { |locn| locn['location_code'] == bin.location_code }
  end

  #PROPER METHOD NAME?????
  def filter_pre_sort_locations(location_candidates)
    bin = Bin.find_by_bin_number(@rep_bin)
    if bin.destination_process_var.to_s.upcase == 'PRESORT' || bin.destination_process_var.to_s.upcase == 'OCHARD_RUN'
      location_candidates.delete_if { |locn| !locn['location_code'].to_s.include?('RA_6') && !locn['location_code'].to_s.include?('RA_7') }
    end
  end

  #PROPER METHOD NAME?????
  def filter_low_capacity_locations(location_candidates)
    locns = location_candidates.find_all{ |locn| (locn['units_in_location'].to_i + 1) > (locn['location_maximum_units'].to_i) }
    location_candidates.delete_if { |locn| (locn['units_in_location'].to_i + 1) > (locn['location_maximum_units'].to_i) }
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
    location_candidates.delete_if { |locn| locn['location_status'].to_s.upcase.include?('SEALED') || locn['location_status'].to_s.upcase.include?('GAS') }
  end

  def get_valid_locations
    location_candidates = Bin.valid_storage_locations?(@rep_bin)
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

    screen_attributes = {:auto_submit => "true", :auto_submit_to => "location_scanned", :content_header_caption => "scan valid location"}
    buttons = {"B3Label" => "", "B2Label" => "", "B1Submit" => "location_scanned", "B1Label" => "submit", "B1Enable" => "false", "B2Enable" => "false", "B3Enable" => "false"}
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    return result_screen_def
  end

  def location_scanned
    if(error=valid_scanned_location?)
      return build_force_move_screen(error)
    else
      return putaway_bin_trans
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

    scanned_bin = Bin.find_by_bin_number(@bins[0])
    track_indicator_rec  = TrackSlmsIndicator.find(scanned_bin.track_indicator1_id)
    query = " select locations.location_code,locations.location_maximum_units,locations.units_in_location,locations.location_status,locations.unavailable
              ,bin_location_setups.priority
              from locations
              join bin_location_setups on bin_location_setups.location_id=locations.id
              where (locations.location_code='#{@location_code}')
               and ((bin_location_setups.track_slms_indicator_code='ALL' or bin_location_setups.track_slms_indicator_code='#{track_indicator_rec.track_slms_indicator_code}')
               and (bin_location_setups.farm_code='ALL' or bin_location_setups.farm_code='#{scanned_bin.farm.farm_code}')
               and (bin_location_setups.rmt_variety_code='ALL' or bin_location_setups.rmt_variety_code='#{scanned_bin.rmt_product.variety.rmt_variety_code}')
               and (bin_location_setups.commodity_code='ALL' or bin_location_setups.commodity_code='#{scanned_bin.rmt_product.commodity_code}')
               and (bin_location_setups.assignment_code='ALL' or bin_location_setups.assignment_code='#{scanned_bin.destination_process_var}')
               and (bin_location_setups.size_code='ALL' or bin_location_setups.size_code='#{scanned_bin.rmt_product.size_code}')
               and (bin_location_setups.ripe_point_code='ALL' or bin_location_setups.ripe_point_code='#{scanned_bin.rmt_product.ripe_point_code}')
               and (bin_location_setups.season='ALL' or bin_location_setups.season='#{scanned_bin.season_code}')
               and (bin_location_setups.product_class_code='ALL' or bin_location_setups.product_class_code='#{scanned_bin.rmt_product.product_class_code}')
               and (bin_location_setups.rmt_product_code='ALL' or bin_location_setups.rmt_product_code='#{scanned_bin.rmt_product.rmt_product_code}')
               and (bin_location_setups.rmt_product_type_code='ALL' or bin_location_setups.rmt_product_type_code='#{scanned_bin.rmt_product.rmt_product_type_code}')
               and (bin_location_setups.treatment_code='ALL' or bin_location_setups.treatment_code='#{scanned_bin.rmt_product.treatment_code}'))
              order by bin_location_setups.priority DESC
          "
    if((@valid_locations=ActiveRecord::Base.connection.select_all(query)).length > 0)
      filter_current_location(@valid_locations)
      return ["bin is already in the scanned location[#{@location_code}] "] if(@valid_locations.length == 0)
      filter_pre_sort_locations(@valid_locations)
      return ["scanned location[#{@location_code}] is not in RA_6 or RA_7"] if(@valid_locations.length == 0)
      filter_low_capacity_locations(@valid_locations)
      return ["#{@location_code} is full"] if(@valid_locations.length == 0)
      filter_unavailable_locations(@valid_locations)
      return ["scanned location[#{@location_code}] is unavailable"] if(@valid_locations.length == 0)
      filter_sealed_locations(@valid_locations)
      return ["scanned location[#{@location_code}] is sealed or GAS"] if(@valid_locations.length == 0)
    else
      return ["scanned location[#{@location_code}] has not been setup for this kind of bin"]
    end
    return nil
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
        scanned_bin = Bin.find_by_bin_number(@bins[0])
        #raise "bin: #{@bins[0].to_s} not found" if !scanned_bin

        track_indicator_rec  = TrackSlmsIndicator.find(scanned_bin.track_indicator1_id)
        query = " select locations.location_code,locations.location_maximum_units,locations.units_in_location,locations.location_status,locations.unavailable
                  ,bin_location_setups.priority
                  from locations
                  join bin_location_setups on bin_location_setups.location_id=locations.id
                  where (locations.location_code='#{@location_code}')
                   and ((bin_location_setups.track_slms_indicator_code='ALL' or bin_location_setups.track_slms_indicator_code='#{track_indicator_rec.track_slms_indicator_code}')
                   and (bin_location_setups.farm_code='ALL' or bin_location_setups.farm_code='#{scanned_bin.farm.farm_code}')
                   and (bin_location_setups.rmt_variety_code='ALL' or bin_location_setups.rmt_variety_code='#{scanned_bin.rmt_product.variety.rmt_variety_code}')
                   and (bin_location_setups.commodity_code='ALL' or bin_location_setups.commodity_code='#{scanned_bin.rmt_product.commodity_code}')
                   and (bin_location_setups.assignment_code='ALL' or bin_location_setups.assignment_code='#{scanned_bin.destination_process_var}')
                   and (bin_location_setups.size_code='ALL' or bin_location_setups.size_code='#{scanned_bin.rmt_product.size_code}')
                   and (bin_location_setups.ripe_point_code='ALL' or bin_location_setups.ripe_point_code='#{scanned_bin.rmt_product.ripe_point_code}')
                   and (bin_location_setups.season='ALL' or bin_location_setups.season='#{scanned_bin.season_code}')
                   and (bin_location_setups.product_class_code='ALL' or bin_location_setups.product_class_code='#{scanned_bin.rmt_product.product_class_code}')
                   and (bin_location_setups.rmt_product_code='ALL' or bin_location_setups.rmt_product_code='#{scanned_bin.rmt_product.rmt_product_code}')
                   and (bin_location_setups.rmt_product_type_code='ALL' or bin_location_setups.rmt_product_type_code='#{scanned_bin.rmt_product.rmt_product_type_code}')
                   and (bin_location_setups.treatment_code='ALL' or bin_location_setups.treatment_code='#{scanned_bin.rmt_product.treatment_code}'))
                  order by bin_location_setups.priority DESC
              "
        if((@valid_locations=ActiveRecord::Base.connection.select_all(query)).length > 0)
          filter_current_location(@valid_locations)
          return build_force_move_screen(["bin is already in the scanned location[#{@location_code}] "]) if(@valid_locations.length == 0)
          filter_low_capacity_locations(@valid_locations)
          return build_force_move_screen(["#{@location_code} is full"]) if(@valid_locations.length == 0)
          filter_unavailable_locations(@valid_locations)
          return build_force_move_screen(["scanned location[#{@location_code}] is unavailable"]) if(@valid_locations.length == 0)
          filter_sealed_locations(@valid_locations)
          return build_force_move_screen(["scanned location[#{@location_code}] is sealed or GAS"]) if(@valid_locations.length == 0)
        end
        return putaway_bin_trans
      else
        return build_force_move_screen(self.pdt_screen_def.get_control_value("error"))
      end
    end
  end

  def putaway_bin_trans
    ActiveRecord::Base.transaction do
      Inventory.move_stock('PUTAWAY_BIN', @bin, @location_code, @bins)

      self.set_repeat_process_flag
    end
  end

end
