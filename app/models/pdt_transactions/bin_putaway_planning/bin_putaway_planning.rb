class BinPutawayPlanning < PDTTransaction

  attr_accessor :coldroom, :qty_bins, :scanned_bins, :current_index, :coldroom_id, :current_bins_index, :new
  # coldroom_location_id
  # putaway_location_id
  # qty_bins_to_putaway
  # bins_to_putaway
  # bins_putaway_completed
  # created_on
  # completed_on
  # updated_at
  # user_name

  def initialize(new = nil, index = nil)
    @new = new
    @current_bins_index = index
  end


  def create_putaway_plan(new = nil)
    coldroom, qty_bins = get_user_latest_planning_plan

    field_configs = Array.new
    field_configs[field_configs.length] = {:type => "drop_down", :name => "coldroom", :is_required => "true", :list => ClientSettings.bin_putaway_coldrooms.join(","), :value => coldroom}
    field_configs[field_configs.length] = {:type => "text_box", :name => "qty_bins", :is_required => "true", :value => qty_bins}

    screen_attributes = {:auto_submit => "false", :content_header_caption => "create bin putaway plan"}
    buttons = {"B3Label" => "Clear", "B2Label" => "Cancel", "B1Submit" => "create_putaway_plan_submit", "B1Label" => "Submit", "B1Enable" => "true", "B2Enable" => "false", "B3Enable" => "false"}
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def create_putaway_plan_submit
    @coldroom = self.pdt_screen_def.get_control_value("coldroom").to_s.strip
    @qty_bins = self.pdt_screen_def.get_control_value("qty_bins").to_s.strip
    @coldroom_id = ActiveRecord::Base.connection.select_one("select id from locations where location_code = '#{@coldroom}'")['id']
    @scanned_bins = Array.new

    next_state = BinPutawayScanning.new(self)
    self.set_active_state(next_state)
    return next_state.build_default_screen
  end


  private

  def get_user_latest_planning_plan
    coldroom = nil
    qty_bins = nil
    latest_bin_putaway_plan = ActiveRecord::Base.connection.select_one(
        "select l.location_code ,bpp.coldroom_location_id,bpp.qty_bins_to_putaway
                                  from locations l
                                  join bin_putaway_plans bpp on bpp.coldroom_location_id = l.id
                                  where bpp.user_name  = '#{self.pdt_screen_def.user}'
                                  order by bpp.updated_at desc limit 1")

    qty_bins = latest_bin_putaway_plan['qty_bins_to_putaway'].to_s.strip if latest_bin_putaway_plan
    coldroom = latest_bin_putaway_plan['location_code'] if latest_bin_putaway_plan
    return coldroom, qty_bins
  end


end
