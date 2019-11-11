class ReceiveIntakeBin < PDTTransaction

  attr_accessor :full_bins, :delivery_number, :half_bins, :active_bins_list, :qty_full_bins_required, :qty_half_bins_required, :active_required_qty, :active_scan_prompt, :delivery_id, :delivery_rmt_variety
  attr_accessor :scan ,:track_slms_indicator_id, :track_slms_indicator_code, :sample_bins, :sample_bins_sequences, :bin_number, :delivery_id, :bin_number_ref, :farm_code

  def permission?
    permision_name = @pdt_method.method_name
     if permision_name == "complete_delivery"
      return "yes"
     else
       return nil
     end
  end

  def build_default_screen
    field_configs                       = Array.new
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"delivery_number", :label => "delivery preprinted", :is_required=>"true", :scan_field => true, :submit_form => true}

    screen_attributes                   = {:auto_submit=>"true", :auto_submit_to=>"delivery_number_submit", :content_header_caption=>"enter_delivery_number"}
    buttons                             = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"delivery_number_submit", "B1Label"=>"submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins                             = nil
    result_screen_def                   = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def
  end

  def enter_delivery_number
    build_default_screen
  end


  def delivery_number_submit
    delivery = Delivery.find_by_delivery_number_preprinted(self.pdt_screen_def.get_control_value("delivery_number").strip)
    if delivery == nil
      return PDTTransaction.build_msg_screen_definition("delivery number does not exists ", nil, nil, nil)
    end
    @delivery_number        = delivery.delivery_number
    @delivery_rmt_variety = delivery.rmt_variety_code
    @delivery_id            = delivery.id
    @qty_full_bins_required = delivery.quantity_full_bins
    @qty_half_bins_required = delivery.quantity_partial_units
    @qty_half_bins_required = 0 if !@qty_half_bins_required
    @qty_full_bins_required = 0 if !@qty_full_bins_required
    @farm_code           = delivery.farm_code
    @active_required_qty = self.qty_full_bins_required
    @full_bins           = DeliveryBinScannedList.new(self.delivery_id, "full_bins")
    @half_bins           = DeliveryBinScannedList.new(self.delivery_id, "half_bins")
    @sample_bins         = DeliveryBinScannedList.new(self.delivery_id, "sample_bins")
    @scan              = DeliveryBinScannedList.new(self.delivery_id, nil)
    @active_bins_list    = nil

    track_indicator_for_delivery  = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{@delivery_id}' order by id asc")
    track_indicator_rec  = track_indicator_for_delivery[0]
    if  track_indicator_rec
      @track_slms_indicator_id   = track_indicator_rec.track_slms_indicator_id
      @track_slms_indicator_code = track_indicator_rec.track_slms_indicator_code
    end
    @sample_bins_sequences     = delivery.delivery_sample_bins.map { |f| f.sample_bin_sequence_number }

    delivery_scans             =DeliveryScan.find_all_by_delivery_id(delivery.id)
    if !delivery_scans.empty?
      screen = self.check_mode("full_bins")
      if screen =~ /\bscan successfully switch to/ || screen == true
      else
        return screen
      end
    else
      delivery_route_steps = DeliveryRouteStep.find_by_sql("select *  from  delivery_route_steps  where delivery_id = '#{ @delivery_id }' and
     ( route_step_code = '100_fruit_sample_completed' or  route_step_code='intake_bin_scanning') order by id asc")

      fruit_sample_completed   = delivery_route_steps[0].date_completed
      intake_bin_scan_completed   = delivery_route_steps[1].date_completed
      # if  fruit_sample_completed   == nil
      #   return PDTTransaction.build_msg_screen_definition("delivery route steps not done for route_step_code :'#{delivery_route_steps[0].route_step_code}'", nil, nil, nil)
      # end
      if intake_bin_scan_completed!= nil
        return PDTTransaction.build_msg_screen_definition("Bin scan has already completed successfully  ", nil, nil, nil)
      end

      delivery_scan            =DeliveryScan.new
      delivery_scan.delivery_id= delivery.id
      delivery_scan.save

      set_scan_mode_to_full_bins

    end

    # if((delivery.commodity_code=='AP' || delivery.commodity_code=='PL') && (!track_indicator_for_delivery[2]))
    #   result_screen = PDTTransaction.build_msg_screen_definition(["Delivery needs a third indicator of type[pressure_ripeness]"], nil, nil, nil)
    #   return result_screen
    # end

    next_state = BinScanning.new(self)
    self.set_active_state(next_state)
    return next_state.build_default_screen
  end

  def active_bins_list
    @active_bins_list = self.half_bins if self.active_scan_prompt =="half_bins"
    @active_bins_list = self.full_bins if self.active_scan_prompt =="full_bins"
    return @active_bins_list
  end

  def change_mode_prompt(current_mode, new_mode)
    @active_scan_prompt= new_mode
    result             = "scan successfully switch to #{new_mode} as  #{current_mode} bins are all scanned "
    return result
  end

  def check_mode(mode)
    full_bins = self.full_bins.length()
    half_bins = self.half_bins.length()
    if  (full_bins==self.qty_full_bins_required && half_bins == self.qty_half_bins_required)
      if (self.set_transaction_complete_flag == true)
        result        = "Bin scan has already completed successfully "
        result_screen = PDTTransaction.build_msg_screen_definition(result, nil, nil, nil)
        return result_screen
      end
    end


    if self.qty_full_bins_required == full_bins
      if mode == "full_bins"
        change_mode_prompt(mode, "half_bins")
      else
        @active_scan_prompt = mode
        self.active_bins_list
        result = true
      end
    elsif self.qty_half_bins_required == half_bins
      if mode == "half_bins"
        change_mode_prompt(mode, "full_bins")
      else
        @active_scan_prompt = mode
        self.active_bins_list
        result = true
      end
    else
      @active_scan_prompt = mode
      self.active_bins_list
      result = true
    end

  end

  def set_scan_mode_to_full_bins
    @active_scan_prompt  = "full_bins"
    @active_required_qty = self.qty_full_bins_required
  end

  def set_scan_mode_to_half_bins
    @active_scan_prompt  = "half_bins"
    @active_required_qty = self.qty_half_bins_required
  end

  def qty_full_bins
    delivery                = Delivery.find_by_delivery_number_preprinted(self.pdt_screen_def.get_control_value("delivery_number").strip)
    @qty_full_bins_required = delivery.quantity_full_bins
    @qty_full_bins_required = 0 if !@qty_full_bins_required
    return @qty_full_bins_required
  end

  def qty_half_bins
    delivery                = Delivery.find_by_delivery_number_preprinted(self.pdt_screen_def.get_control_value("delivery_number").strip)
    @qty_half_bins_required = delivery.quantity_partial_units
    @qty_half_bins_required = 0 if !@qty_half_bins_required
    return @qty_half_bins_required
  end

  def is_sample_bin?(bin_number)

    if self.sample_bins.include?(bin_number)
      return true
    else
      return false
    end

  end

  def is_half_bin?(bin_number)

    if self.half_bins.include?(bin_number)
      return true
    else
      return false
    end
  end

  def create_bin(bin_number)
    delivery_track                   = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{self.delivery_id}' order by id asc ")

    @delivery                        = Delivery.find(self.delivery_id)
    pack_material_code               = @delivery.pack_material_product_code

    pack_material_product            = PackMaterialProduct.find_by_sql("select * from pack_material_products where pack_material_product_code = '#{pack_material_code}'")[0]
    pack_material_product_id         = pack_material_product.id

    bin_rec                          = Bin.new
    bin_rec.bin_number               = bin_number
    bin_rec.rmt_product_id           = @delivery.rmt_product_id
    bin_rec.season_code              = @delivery.season_code
    bin_rec.delivery_id              = @delivery.id
    bin_rec.farm_id                  = @delivery.farm_id
    bin_rec.destination_process_var  = @delivery.destination_process_var
    bin_rec.pack_material_product_id = pack_material_product_id
    bin_rec.bin_receive_date_time    = Time.now()
    bin_rec.orchard_code             = @delivery.orchard.representative_orchard ? @delivery.orchard.representative_orchard.orchard_code : ""
    bin_rec.user_name                = self.pdt_screen_def.user
    bin_rec.is_half_bin = true if is_half_bin?(bin_number) == true
    bin_rec.is_sample_bin = true if is_sample_bin?(bin_number) == true
    bin_rec.track_indicator1_id = delivery_track[0].track_slms_indicator_id if  delivery_track[0]
    bin_rec.track_indicator2_id = delivery_track[1].track_slms_indicator_id if  delivery_track[1]
    bin_rec.track_indicator3_id = delivery_track[2].track_slms_indicator_id if  delivery_track[2]
    bin_rec.track_indicator4_id = delivery_track[3].track_slms_indicator_id if  delivery_track[3]
    bin_rec.track_indicator5_id = delivery_track[4].track_slms_indicator_id if  delivery_track[4]
    bin_rec.save
    return bin_rec
  end

  def complete_bin_scan_trans

    DeliveryRouteStep.update_all(ActiveRecord::Base.extend_set_sql_with_request("date_activated = '#{Time.now}'","delivery_route_steps"), "delivery_route_steps.delivery_id = '#{@delivery_id}' and delivery_route_steps.route_step_code = 'intake_bin_scanning'")

    begin
      ActiveRecord::Base.transaction do
        bin_nums=Array.new
        bins = []
        self.full_bins.each { |b| bin_nums << b }
        self.half_bins.each { |c| bin_nums << c }

        for bin_number in bin_nums
          bins << create_bin(bin_number)
        end

        updates = []
        (1..5).each do |n|
          updates << get_unupdated_bin_track_indicators(bins, n)
        end

        Bin.update_all(ActiveRecord::Base.extend_set_sql_with_request(updates.compact.join(','),"bins"), "bins.delivery_id=#{@delivery.id}") if(!updates.compact.empty?)

        Inventory.create_stock(@delivery.owner_party_role_id, "BIN", @delivery.farm_code, @delivery.truck_registration_number, "receive_intake_bins", @delivery.delivery_number, "INTAKE", bin_nums)

        delivery                 = Delivery.find_by_delivery_number(@delivery_number)
        delivery.delivery_status = "intake_bin_scan_completed"
        delivery.update

        DeliveryRouteStep.update_all(ActiveRecord::Base.extend_set_sql_with_request("date_completed = '#{Time.now()}' ","delivery_route_steps"), "delivery_route_steps.delivery_id = '#{delivery.id}' and delivery_route_steps.route_step_code = 'intake_bin_scanning'")

        self.set_transaction_complete_flag
        result        = ["Bin scan completed successfully "]

        result_screen = PDTTransaction.build_msg_screen_definition(result, nil, nil, nil)

        return result_screen

      end
    rescue
      DeliveryRouteStep.update_all(ActiveRecord::Base.extend_set_sql_with_request("date_activated = null","delivery_route_steps"), "delivery_route_steps.delivery_id = '#{@delivery_id}' and delivery_route_steps.route_step_code = 'intake_bin_scanning'")
      raise $!
    end
  end

  def get_unupdated_bin_track_indicators(bins, n)
    if ((failed=bins.find { |d| !eval("d.track_indicator#{n}_id") }) && (succ=bins.find { |d| eval("d.track_indicator#{n}_id") }))
      return "track_indicator#{n}_id = #{eval("succ.track_indicator#{n}_id")} "
    end
  end
end
