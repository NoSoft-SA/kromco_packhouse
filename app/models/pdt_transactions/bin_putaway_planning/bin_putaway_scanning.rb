class BinPutawayScanning < PDTTransactionState

  def initialize(parent)
    @parent = parent
    @current_scanned_bin_index = 0
    @parent.bpp = nil
  end

  def restart_scanning
    @parent.bin_putaway_plan_id = nil
    @parent.positions_available = nil
    @parent.current_index = nil
    @parent.current_bins_index = nil
    @parent.new = nil
    @parent.location_code = nil
    @parent.spaces_left = nil
    @parent.scanned_bins = []
    @parent.location_id = nil
    @parent.bin_fruit_spec = nil
    build_default_screen
  end

  def build_default_screen

   field_configs = Array.new
    field_configs[field_configs.length] = {:type => "static_text", :name => "room", :value => @parent.coldroom}
    field_configs[field_configs.length] = {:type => "static_text", :name => "putaway_loc", :value => @parent.location_code}
    if @adjusted_qty
      field_configs[field_configs.length] = {:type => "static_text", :name => "qty", :value => @parent.qty_bins.to_s + " " + @adjusted_qty}
    else
      field_configs[field_configs.length] = {:type => "static_text", :name => "qty", :value => @parent.qty_bins}
    end
    field_configs[field_configs.length] = {:type => "static_text", :name => "bins_scanned", :value => "#{@parent.scanned_bins.length().to_s}"}
    #field_configs[field_configs.length] = {:type => "static_text", :name => "space_left", :value => "#{@parent.spaces_left}"}
    field_configs[field_configs.length] = {:type => "text_box", :name => "bin_number",
                                            :scan_only => "false", :scan_field => true,
                                           :submit_form => true}
    field_configs[field_configs.length()] = {:type => "check_box", :name => "force_complete",:submit_form => true} #,:scan_field => true,:submit_form => true}#,:scan_only=>"true"

    screen_attributes = {:auto_submit => "true", :auto_submit_to => "bin_scanned_submit", :cache_screen => true}
    buttons = {"B3Label" => "", "B2Label" => "", "B1Submit" => "bin_scanned_submit", "B1Label" => "submit", "B1Enable" => "false", "B2Enable" => "false", "B3Enable" => "false"}

    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def bin_scanned_submit

    error = validate
    if (error = validate) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
      return result_screen
    end

    @parent.scanned_bins.push(@bin_number) if @bin_number
    if @force_complete == "true" && @parent.scanned_bins.length >=1 && !@bin_number
      process_scanned_bins
    else
      process_bin_scanned_submit
    end

  end

  def receive_call_back
    self.parent.clear_active_state
    @parent.clear_active_state
    process_bin_scanned_submit(true)
  end

  def process_bin_scanned_submit(from_another_class=nil)
    get_bin_type_and_location if !from_another_class

    get_locations if @parent.bin && @parent.scanned_bins.length == 1

    create_bin_putaway if @parent.scanned_bins.length == 1 && !@parent.bpp

    @parent.spaces_left = Location.get_spaces_in_location(@parent.location_code, @parent.scanned_bins.length,@parent.pdt_screen_def.user,@parent.created_on) if @parent.location_code

    #TODO: REvise this part
    if @parent.spaces_left && @parent.scanned_bins.length == 1 && (@parent.spaces_left.to_i < @parent.qty_bins.to_i)
      if @parent.spaces_left < 0 || @parent.spaces_left ==  0
        @parent.error_str  = "inadequate space."
        return render_select_location_state
      else
        @parent.qty_bins = @parent.spaces_left + 1
        @adjusted_qty =  "(adjusted to space)"
      end
    elsif ( @parent.spaces_left &&  @parent.spaces_left.to_i == 0 && (@parent.scanned_bins.length < qty_bins_remaining))
          @parent.error_str = "inadequate space."
          return render_select_location_state
    end

    matching_error = match_existing_bins if @parent.scanned_bins.length > 1
    if matching_error
      result_screen = PDTTransaction.build_msg_screen_definition("#{matching_error}", nil, nil, nil)
      return result_screen
    end

    if !@parent.location_code
      return render_select_location_state
    end

    process_scanned_bins
  end

  def get_bin_type_and_location
    bin = get_bin_type_and_fruit_spec("bins.bin_number = '#{@bin_number}' ") if @parent.scanned_bins.length == 1

    @parent.bin  = bin

    assign_bin_variables(bin) if bin && @parent.scanned_bins.length == 1

  end

  def render_select_location_state
    @parent.clear_active_state
    next_state = SelectLocation.new(@parent)
    result_screen = next_state.build_default_screen
    @parent.set_active_state(next_state)
    return result_screen
  end

  def qty_bins_remaining
    return @parent.qty_bins.to_i - self.parent.scanned_bins.length()
  end

  def match_existing_bins
    bin = get_bin_type_and_fruit_spec("bins.bin_number = '#{@bin_number}' ")
      error = []
    error << " stock type"  if @parent.bin_fruit_spec['stock_type_code'] != bin['stock_type_code']
    error <<  "commodity" if @parent.bin_fruit_spec['commodity'] != bin['commodity_code']
    error <<  "variety" if @parent.bin_fruit_spec['variety'] != bin['variety_code']
    error <<  "size" if @parent.bin_fruit_spec['size'] != bin['size_code']
    error <<  "class" if @parent.bin_fruit_spec['class'] != bin['product_class_code']
    error <<  "treatment" if @parent.bin_fruit_spec['treatment'] != bin['treatment_code']
    error <<  "farm" if (@parent.bin_fruit_spec['farm'] != bin['farm_code']) && (@parent.bin_fruit_spec['farm'] && bin['farm_code'])
    error <<  "track_indicator_code" if @parent.bin_fruit_spec['track_indicator1_id'] != bin['track_indicator1_id']
    error << "undo and scan another"
    return error.join("<BR>") if !error.empty?
    return nil if error.empty?
   end

  def create_bin_putaway

    if !@parent.bpp
      bin_nums = {}
    @parent.scanned_bins.each do |num|
      bin_nums[num] = "'#{num}'"
    end
    bin_putaway_plan = BinPutawayPlan.new
    bin_putaway_plan.coldroom_location_id = @parent.coldroom_id
    bin_putaway_plan.putaway_location_id = @parent.location_id
    bin_putaway_plan.qty_bins_to_putaway = @parent.qty_bins.to_i
    #bin_putaway_plan.bins_to_putaway = bin_nums
    #bin_putaway_plan.bins_putaway_completed = bin_nums
    bin_putaway_plan.created_on = Time.now.to_formatted_s(:db)
    #bin_putaway_plan.completed = true
    #bin_putaway_plan.updated_at = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
    bin_putaway_plan.user_name = @parent.pdt_screen_def.user
    bin_putaway_plan.save

    @parent.created_on = bin_putaway_plan.created_on.to_formatted_s(:db)
    @parent.bin_putaway_plan_id = bin_putaway_plan.id
    @bpp = true
    @parent.bpp = @bpp
      end
  end


  def get_locations
    location = get_matched_bin_location
    @parent.location_code = location['location_code'] if location
    @parent.location_id = location['location_id'] if location

  end


  def get_units_in_location(location)
    units_in_location = 0
    spaces_left = ActiveRecord::Base.connection.select_one("
                        select
                        l.location_maximum_units - (COALESCE(l.units_in_location,0) + COALESCE(bpp.qty_bins_to_putaway,0)) as spaces_left
                        from  locations l
                        left join bin_putaway_plans bpp on bpp.putaway_location_id = l.id
                        where l.location_code = '#{location}'
                                      ")['spaces_left'] if location

    return spaces_left.to_i
    return units_in_location if !spaces_left
  end

  def get_location_where
    where = []
    @parent.bin_fruit_spec.each do |k,v|
      if k != "stock_type_code"
        where << "rmt.#{k} = '#{v}' " if k != "track_indicator1_id"
        where << "b.#{k}   =  #{v}" if k == "track_indicator1_id"
      end

    end
   return where.join(" AND ")
  end

  def get_matched_bin_location
    where_clause = get_location_where
    location = ActiveRecord::Base.connection.select_one("
                  select * from (
                  select distinct l.location_code , l.id  as location_id,l.updated_at,
                  units_in_location,location_maximum_units,l.loading_out,l.location_code,l.location_barcode,
                  case
                  when units_in_location=location_maximum_units then '100'
                  when units_in_location=0 then '1'
                  when units_in_location<location_maximum_units then '0'
                  else 'n.a.' end as fullness
                  from locations l
                  join stock_items si on si.location_id = l.id
                  join bins b on si.inventory_reference = b.bin_number
                  join rmt_products rmt ON b.rmt_product_id = rmt.id
				          left join farms ON b.farm_id = farms.id
                  where
                  ((si.destroyed IS NULL) OR (si.destroyed = false)) and
                  l.parent_location_code  = '#{@parent.coldroom}'  and
                  l.loading_out is not true and
                   l.units_in_location < l.location_maximum_units and
                    #{where_clause}
                   ) as sq
                  order by fullness ,updated_at desc limit 1
                                                        ")


    @parent.error_str = "no matched location" if !location
    return location if location

  end

  def location_status(location)
    location_status = Location.check_location_status(location.location_barcode)
    if  location_status  != nil
      if location_status == "SEALED"
        error = "Location is SEALED "
      elsif location_status == "GAS"
        error = "Location status:GAS "
      end
      if error
        @parent.error_str  = error
        return render_select_location_state
      else
        return location
      end
    else
      return location
    end
  end

  def get_bin_type_and_fruit_spec(where_clause)
    bin = ActiveRecord::Base.connection.select_all("
            select  distinct bins.bin_number,bins.id,
                    rmt.rmt_product_code,
                    stock_type_code,
                    si.location_code,
                    rmt.commodity_code,
                    rmt.variety_code,
                    rmt.size_code,
                    rmt.product_class_code,
                    rmt.treatment_code,
                    farms.farm_code,
                    bins.track_indicator1_id
            from bins
                     JOIN stock_items si ON si.inventory_reference=bins.bin_number
                     JOIN rmt_products rmt ON bins.rmt_product_id = rmt.id
                     LEFT JOIN farms ON bins.farm_id = farms.id
					           JOIN locations l on si.location_id = l.id
					  WHERE  ((si.destroyed IS NULL) OR (si.destroyed = false)) and #{where_clause}
                                                   ")[0]

    #assign_bin_variables(bin) if bin && @parent.scanned_bins.length == 1
    return bin
  end

  def assign_bin_variables(bin)
    @stock_type_code = bin['stock_type_code']
    @commodity_code = bin['commodity_code']
    @variety_code = bin['variety_code']
    @size_code = bin['size_code']
    @product_class_code = bin['product_class_code']
    @treatment_code = bin['treatment_code']
    @track_indicator1_id = bin['track_indicator1_id']
    @farm_code = bin['farm_code']

    @parent.stock_type_code = bin['stock_type_code']
    @parent.commodity_code = bin['commodity_code']
    @parent.variety_code = bin['variety_code']
    @parent.size_code = bin['size_code']
    @parent.product_class_code = bin['product_class_code']
    @parent.treatment_code = bin['treatment_code']
    @parent.track_indicator1_id = bin['track_indicator1_id']
    @parent.farm_code = bin['farm_code']

    get_bin_fruit_spec
   #  @parent.bin_fruit_spec = {
   # 'stock_type_code' => bin['stock_type_code'],
   #  'commodity_code' => bin['commodity_code'],
   #  'variety_code' => bin['variety_code'],
   #  'size_code' => bin['size_code'],
   #  'product_class_code' => bin['product_class_code'],
   #  'treatment_code' => bin['treatment_code'],
   #  'track_indicator1_id' => bin['track_indicator1_id']
   #  }

  end

  def get_bin_fruit_spec
    # bin_fruit_spec = BinPutawayPlanningRule.new(
    # @parent.stock_type_code,
    # @parent.commodity_code,
    # @parent.variety_code,
    # @parent.size_code,
    # @parent.product_class_code,
    # @parent.treatment_code,
    # @parent.track_indicator1_id,
    # @parent.farm_code,
    # @parent.bin,
    # @parent.scanned_bins
    # )
    # @parent.bin_fruit_spec = bin_fruit_spec

    self.parent.clear_active_state
    next_state = BinPutawayPlanningRule.new(true, @parent)
    @parent.set_active_state(next_state)
    next_state.call
  end


  def validate
    scan_bin_number = @parent.pdt_screen_def.get_control_value("bin_number").strip
    @force_complete =  @parent.pdt_screen_def.get_control_value("force_complete").strip

    if @force_complete == "true" && @parent.scanned_bins.length >= 1
      @bin_number = nil
    else
      bin = Bin.find_by_bin_number(scan_bin_number)

      if bin == nil
      error = ["Bin number :'#{scan_bin_number}' does not exist "]
      return error
    end

    @bin_number = bin.bin_number


    if @parent.scanned_bins.include?(bin.bin_number)
      error = ["Bin number : '#{bin.bin_number}' has already been scanned"]
      return error
    end

    on_a_tripsheet = Bin.is_on_tripsheet?(scan_bin_number)
    if on_a_tripsheet
      error = ["Bin number :'#{scan_bin_number}' is already on tripsheet: #{on_a_tripsheet} "]
      return error
    end

    inv_reference = bin.bin_number.to_s
    stock_item = StockItem.find_by_inventory_reference(inv_reference)
    if !stock_item
      error = ["Bin can not be received,its not a stock item "]
      return error
    end

    on_a_bin_plan = BinPutawayPlan.is_on_a_putaway_plan?(scan_bin_number)
    if on_a_bin_plan
      error = ["Bin can not be received,its on another bin putaway plan "]
      return error
    end
    end
  end


  def process_scanned_bins
    @quantity_bins_remaining = qty_bins_remaining
    @parent.quantity_bins_remaining = @quantity_bins_remaining
    if (@quantity_bins_remaining && @quantity_bins_remaining <= 0) || @force_complete =="true"
      #TODO: should it be commented out?
        return transition_to_bulk_putaway
    else
       self.parent.clear_active_state
       @parent.clear_active_state
      return self.build_default_screen
    end
  end

  def transition_to_bulk_putaway
    get_location_positions_availabe

    next_state = BulkPutawayBin.new(@parent)
    result_screen = next_state.build_bulk_putaway_screen
    @parent.set_active_state(next_state)
    return result_screen
  end

  def get_location_positions_availabe
    @parent.positions_available = ActiveRecord::Base.connection.select_one("
                        select
                        l.location_maximum_units - COALESCE(l.units_in_location,0) as positions_available
                        from  locations l
                        where l.location_code = '#{@parent.location_code}'
                                      ")['positions_available']
  end


end
