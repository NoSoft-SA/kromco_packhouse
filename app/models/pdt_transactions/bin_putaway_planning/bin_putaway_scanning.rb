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
    field_configs[field_configs.length] = {:type => "static_text", :name => "coldroom", :value => @parent.coldroom}
    field_configs[field_configs.length] = {:type => "static_text", :name => "putaway_location", :value => @parent.location_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "qty_bins_to_putaway", :value => @parent.qty_bins}
    field_configs[field_configs.length] = {:type => "static_text", :name => "bins_scanned", :value => "#{@parent.scanned_bins.length().to_s}"}
    field_configs[field_configs.length] = {:type => "static_text", :name => "space_left", :value => "#{@parent.positions_available}"}
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
    else

    bin = get_bin_type_and_frit_spec("bins.bin_number = '#{@bin_number}' ") if @parent.scanned_bins.length == 1

    get_locations if bin && @parent.scanned_bins.length == 1

    @parent.spaces_left = Location.get_spaces_in_location(@parent.location_code, @parent.scanned_bins.length) if @parent.location_code

    matching_error = match_existing_bins if @parent.scanned_bins.length > 1
    if matching_error
      result_screen = PDTTransaction.build_msg_screen_definition("#{matching_error}", nil, nil, nil)
      return result_screen
    end


    if !@parent.location_code || (@parent.spaces_left && @parent.spaces_left.to_i <= 0)
      @parent.clear_active_state
      next_state = SelectLocation.new(@parent)
      result_screen = next_state.build_default_screen
      @parent.set_active_state(next_state)
      return result_screen
    end

    if (@parent.spaces_left && @parent.spaces_left <= 0) && @parent.scanned_bins.length > 1
    elsif @parent.spaces_left && @parent.spaces_left.to_i <= 0
      @parent.clear_active_state
      next_state = SelectLocation.new(@parent)
      result_screen = next_state.build_default_screen
      @parent.set_active_state(next_state)
      return result_screen
    end

    @parent.qty_bins = @parent.spaces_left if @parent.spaces_left.to_i < @parent.qty_bins.to_i

    @parent.positions_available = @parent.spaces_left - @parent.scanned_bins.length
    end

    process_scanned_bins
  end

  def qty_bins_remaining
    return @parent.qty_bins.to_i - self.parent.scanned_bins.length()
  end

  def match_existing_bins
    bin = get_bin_type_and_frit_spec("bins.bin_number = '#{@bin_number}' ")
      error = []
      error << "Scanned bin is of different stock type."  if @parent.bin_fruit_spec['stock_type'] != bin['stock_type_code']
      error <<  "Scanned bin is of different commodity." if @parent.bin_fruit_spec['commodity'] != bin['commodity_code']
      error <<  "Scanned bin is of different variety." if @parent.bin_fruit_spec['variety'] != bin['variety_code']
      error <<  "Scanned bin is of different size." if @parent.bin_fruit_spec['size'] != bin['size_code']
      error <<  "Scanned bin is of different class." if @parent.bin_fruit_spec['class'] != bin['product_class_code']
      error <<  "Scanned bin is of different treatment." if @parent.bin_fruit_spec['treatment'] != bin['treatment_code']
      error <<  "Scanned bin is of different farm." if (@parent.bin_fruit_spec['farm'] != bin['farm_code']) && (@parent.bin_fruit_spec['farm'] && bin['farm_code'])
      error <<  "Scanned bin is of different track_indicator_code." if @parent.bin_fruit_spec['track_indicator_code'] != bin['track_indicator_code']

    return error.join(",") if !error.empty?
    return nil if error.empty?
   end

  def create_bin_putaway
    bin_nums = {}
    @parent.scanned_bins.each do |num|
      bin_nums[num] = "'#{num}'"
    end
    bin_putaway_plan = BinPutawayPlan.new
    bin_putaway_plan.coldroom_location_id = @parent.coldroom_id
    bin_putaway_plan.putaway_location_id = @parent.location_id
    bin_putaway_plan.qty_bins_to_putaway = @parent.qty_bins.to_i
    bin_putaway_plan.bins_to_putaway = bin_nums
    bin_putaway_plan.bins_putaway_completed = bin_nums
    bin_putaway_plan.created_on = Time.now
    bin_putaway_plan.completed = true
    bin_putaway_plan.updated_at = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
    bin_putaway_plan.user_name = @parent.pdt_screen_def.user
    bin_putaway_plan.save

    @parent.bin_putaway_plan_id = bin_putaway_plan.id

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

  def get_matched_bin_location
    location = ActiveRecord::Base.connection.select_one("
                  select * from (
                  select distinct l.location_code , l.id  as location_id,l.updated_at,
                  units_in_location,location_maximum_units,
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
                  rmt.commodity_code      = '#{@commodity_code}'  and
                  rmt.variety_code        = '#{@variety_code}'  and
                  rmt.size_code           = '#{@size_code}'  and
                  rmt.product_class_code  = '#{@product_class_code}'  and
                  rmt.treatment_code      = '#{@treatment_code}'
                  #{@farm_code} ) as sq
                  order by fullness::int ,updated_at desc limit 1
                                                        ")

    location

  end

  def get_bin_type_and_frit_spec(where_clause)
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

    assign_bin_variables(bin) if bin && @parent.scanned_bins.length == 1
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
    farm_code = bin['farm_code']


    if @stock_type_code == 'BIN'
      @farm_code = "and  farms.farm_code like '%'"
      if !farm_code
      else
        @farm_code = "and  farms.farm_code = '#{farm_code}'"
      end
    end

    @parent.bin_fruit_spec = {'stock_type' => @stock_type_code, 'commodity' => @commodity_code,
                       'variety' => @variety_code, 'size' => @size_code, 'class' => @product_class_code,
                       'treatment' => @treatment_code, 'farm' => farm_code,'track_indicator1_id'=> @track_indicator1_id} if @stock_type_code == 'BIN'

    @parent.bin_fruit_spec = {'stock_type' => @stock_type_code, 'commodity' => @commodity_code,
                       'variety' => @variety_code, 'size' => @size_code, 'class' => @product_class_code,
                       'treatment' => @treatment_code,'track_indicator1_id'=> @track_indicator1_id} if @stock_type_code == 'PRESORT'



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
    @parent.positions_available = @parent.spaces_left - @parent.scanned_bins.length

    @quantity_bins_remaining = qty_bins_remaining
    if (@quantity_bins_remaining && @quantity_bins_remaining <= 0) || @force_complete =="true"
        create_bin_putaway
        return transition_to_bulk_putaway
    else
      build_default_screen
    end
  end

  def transition_to_bulk_putaway
    next_state = BulkPutawayBin.new(@parent)
    result_screen = next_state.build_bulk_putaway_screen
    @parent.set_active_state(next_state)
    return result_screen
  end


end
