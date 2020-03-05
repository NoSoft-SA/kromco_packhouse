class BinPutawayScanning < PDTTransactionState

  def initialize(parent)
    @parent = parent
    @current_scanned_bin_index = 0
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
    field_configs[field_configs.length()] = {:type => "check_box", :name => "force_complete", :submit_form => true} #,:scan_field => true,:submit_form => true}#,:scan_only=>"true"

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
    if @force_complete == "true" && @parent.scanned_bins.length >= 1 && !@bin_number
      process_scanned_bins
    else

      bin = process_bin

      get_locations if bin && @parent.scanned_bins.length == 1

      if !@parent.location_code
        return render_select_location_state
      else

        @parent.spaces_left = Location.get_spaces_in_location(@parent.location_code, @parent.scanned_bins.length, @parent.qty_bins.to_i) if @parent.location_code

        if @parent.spaces_left && @parent.scanned_bins.length == 1 && (@parent.spaces_left.to_i < @parent.qty_bins.to_i)
          if @parent.spaces_left < 0 || @parent.spaces_left == 0
            @parent.error_str = "inadequate space."
            return render_select_location_state
          else
            @parent.qty_bins = @parent.spaces_left
            @adjusted_qty = "(adjusted to space)"
          end
        elsif (@parent.spaces_left && @parent.spaces_left.to_i == 0 && (@parent.scanned_bins.length < qty_bins_remaining))
          @parent.error_str = "inadequate space."
          return render_select_location_state
        end

        matching_error = match_existing_bins if @parent.scanned_bins.length > 1
        if matching_error
          result_screen = PDTTransaction.build_msg_screen_definition("#{matching_error}", nil, nil, nil)
          return result_screen
        end
      end
    end

    process_scanned_bins
  end

  def process_bin
    bin = get_bin_fruit_spec("bins.bin_number = '#{@bin_number}' ") if @parent.scanned_bins.length == 1

    @parent.bin = bin

    assign_bin_variables(bin) if bin && @parent.scanned_bins.length == 1

    if @parent.scanned_bins.length == 1
    frut_spec,rule = Location.determine_bin_fruit_spec(@stock_type_code, @commodity_code, @variety_code, @size_code,
                                                  @product_class_code, @treatment_code, @track_indicator1_id,
                                                  @farm_code, nil, @parent.scanned_bins,@coldstore_type)

    str = []
    str << "RULE: #{rule}"
    puts"Scanned Bin number:  #{bin['bin_number']}"
    puts "RULE: #{rule}"
    bin.each do |k,v|
      if %w(commodity_code stock_type_code variety_code size_code product_class_code treatment_code farm_code track_indicator1_id,coldstore_type ).include?(k)
        str << "#{k}" + " " + "#{v}"
        puts "#{k}" + " " + "#{v}"
      end
    end
    log = str.unshift("Scanned Bin number:  #{bin['bin_number']}").join("/n") + "\n"

    RAILS_DEFAULT_LOGGER.info("#{log}")

    @parent.bin_fruit_spec = frut_spec

    end

    bin
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
    bin = get_bin_fruit_spec("bins.bin_number = '#{@bin_number}' ")
    error = []
    error << " stock type" if @parent.bin_fruit_spec['stock_type_code'] && (@parent.bin_fruit_spec['stock_type_code'] != bin['stock_type_code'])
    error << "commodity" if @parent.bin_fruit_spec['commodity_code'] && (@parent.bin_fruit_spec['commodity_code'] != bin['commodity_code'])
    error << "variety" if @parent.bin_fruit_spec['variety_code'] && (@parent.bin_fruit_spec['variety_code'] != bin['variety_code'])
    error << "size" if @parent.bin_fruit_spec['size_code'] && (@parent.bin_fruit_spec['size_code'] != bin['size_code'])
    error << "class" if @parent.bin_fruit_spec['product_class_code'] && (@parent.bin_fruit_spec['product_class_code'] != bin['product_class_code'])
    error << "treatment" if @parent.bin_fruit_spec['treatment_code'] && (@parent.bin_fruit_spec['treatment_code'] != bin['treatment_code'])
    error << "farm" if @parent.bin_fruit_spec['farm_code'] && (@parent.bin_fruit_spec['farm_code'] != bin['farm_code'])
    error << "track_indicator_code" if @parent.bin_fruit_spec['track_indicator1_id'] && (@parent.bin_fruit_spec['track_indicator1_id'] != bin['track_indicator1_id'])
    if !error.empty?
      error << "UNDO and scan another."
      error.unshift("Scanned bin is of different:")
      return error.join("<BR>")
    else
      return nil
    end
  end

  def create_bin_putaway

      if @parent.scanned_bins.length == 1 && !@parent.bin_putaway_plan_id
        bin_nums = {}
        @parent.scanned_bins.each do |num|
          bin_nums[num] = "'#{num}'"
        end
        bin_putaway_plan = BinPutawayPlan.new
        bin_putaway_plan.coldroom_location_id = @parent.coldroom_id
        bin_putaway_plan.putaway_location_id = @parent.location_id
        bin_putaway_plan.qty_bins_to_putaway = @parent.qty_bins.to_i
        bin_putaway_plan.bins_to_putaway = bin_nums
        bin_putaway_plan.created_on = Time.now.to_formatted_s(:db)
        bin_putaway_plan.user_name = @parent.pdt_screen_def.user
        bin_putaway_plan.bin_putaway_code = @parent.pdt_screen_def.user + "_" + @parent.coldroom_id.to_s + "_" + @parent.location_id.to_s + "_" + @parent.qty_bins.to_s + "_" + bin_putaway_plan.created_on.to_s
        bin_putaway_plan.save if @parent.scanned_bins.length == 1 && !@parent.bin_putaway_plan_id
        @parent.created_on = bin_putaway_plan.created_on.to_formatted_s(:db)
        @parent.bin_putaway_plan_id = bin_putaway_plan.id if  !@parent.bin_putaway_plan_id
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
    @parent.bin_fruit_spec.each do |k, v|
      if k != "stock_type_code"
        if k == "track_indicator1_id"
          where << "b.#{k}   =  #{v}"
        elsif k == "farm_code"
          where << "farms.#{k}   =  '#{v}'"
        elsif k == "coldstore_type"
          where << "COALESCE(b.#{k},'RA')  = COALESCE( '#{v}','RA')" if v
          where << "COALESCE(b.#{k},'RA')   =COALESCE(NULL,'RA')" if !v
        else
          where << "rmt.#{k} = '#{v}'"
        end
        # where << "rmt.#{k} = '#{v}' " if k != "track_indicator1_id"
        # where << "b.#{k}   =  #{v}" if k == "track_indicator1_id"
        # where << "farms.#{k}   =  #{v}" if k == "farm_code"

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
                   b.season_code in ('2020_AP','2020_PR') AND
                  ((si.destroyed IS NULL) OR (si.destroyed = false)) and
                  l.parent_location_code  = '#{@parent.coldroom}'  and
                  l.loading_out is not true and
                   l.units_in_location < l.location_maximum_units and
                    #{where_clause}
                   ) as sq
                  order by fullness ,updated_at desc limit 1
                                                        ")

    if !location
      @parent.error_str = "no matched location"
      return render_select_location_state
    else
      location_status(location)
    end


  end

  def location_status(location)
    location_status = Location.check_location_status(location.location_barcode)
    if location_status != nil
      if location_status.upcase.index("SEALED")
        error = "Location is #{location_status} "
      elsif location_status == "GAS"
        error = "Location status:GAS "
      end
      if error
        @parent.error_str = error
        return render_select_location_state
      else
        return location
      end
    else
      return location
    end
  end

  def get_bin_fruit_spec(where_clause)
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
                    bins.track_indicator1_id,
                    bins.coldstore_type
            from bins
                     JOIN stock_items si ON si.inventory_reference=bins.bin_number
                     JOIN rmt_products rmt ON bins.rmt_product_id = rmt.id
                     LEFT JOIN farms ON bins.farm_id = farms.id
					           JOIN locations l on si.location_id = l.id
					  WHERE  ((si.destroyed IS NULL) OR (si.destroyed = false)) and #{where_clause}
                                                   ")[0]

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
    @coldstore_type = bin['coldstore_type']

    @parent.stock_type_code = bin['stock_type_code']
    @parent.commodity_code = bin['commodity_code']
    @parent.variety_code = bin['variety_code']
    @parent.size_code = bin['size_code']
    @parent.product_class_code = bin['product_class_code']
    @parent.treatment_code = bin['treatment_code']
    @parent.track_indicator1_id = bin['track_indicator1_id']
    @parent.farm_code = bin['farm_code']
    @parent.coldstore_type = bin['coldstore_type']

  end


  def validate
    scan_bin_number = @parent.pdt_screen_def.get_control_value("bin_number").strip
    @force_complete = @parent.pdt_screen_def.get_control_value("force_complete").strip


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
    if @parent.scanned_bins.length == 1 && !@parent.bin_putaway_plan_id
      uncompleted_plans = get_uncompleted_plans_by_user
      if uncompleted_plans.to_i >= 1
        error = ["Plan cannot be created.User already have uncompleted plan/s for the same location."]
        result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
        return result_screen
      else
        create_bin_putaway
        @quantity_bins_remaining = qty_bins_remaining
        @parent.quantity_bins_remaining = @quantity_bins_remaining
        if (@quantity_bins_remaining && @quantity_bins_remaining <= 0) || @force_complete == "true"
          return transition_to_bulk_putaway
        else
          build_default_screen
        end
      end
    else
      @quantity_bins_remaining = qty_bins_remaining
      @parent.quantity_bins_remaining = @quantity_bins_remaining
      if (@quantity_bins_remaining && @quantity_bins_remaining <= 0) || @force_complete == "true"
        return transition_to_bulk_putaway
      else
        build_default_screen
      end
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



  def get_uncompleted_plans_by_user
    uncompleted_plans = ActiveRecord::Base.connection.select_one("
                       select COUNT(distinct id)   as plans
                       from bin_putaway_plans
                       where
                       coldroom_location_id = #{@parent.coldroom_id}
                       and putaway_location_id = #{@parent.location_id}
                       and user_name = '#{@parent.pdt_screen_def.user}'
                       and completed is null
                       ")['plans']
  end


end
