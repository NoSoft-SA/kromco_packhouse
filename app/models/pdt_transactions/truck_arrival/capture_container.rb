class CaptureContainer < PDTTransactionState

  def initialize(parent)
    self.parent = parent
  end

  def build_default_screen
    hauliers = PartiesRole.find_by_sql("SELECT party_id,party_name FROM parties_roles WHERE parties_roles.party_type_name = 'ORGANIZATION' and parties_roles.role_name = 'HAULIER'").map { |g| g.party_name }.join(",")
    hauliers = ", ," + hauliers
    stack_types=StackType.find(:all).map{|o|o.stack_type_code}.join(",")
    stack_types = ", ," +  stack_types

    field_configs = Array.new
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"load_number", :value=>@parent.load_number.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"booking_reference", :value=>@parent.booking_reference.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"vessel_code", :value=>@parent.vessel_code.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"voyage_number", :value=>@parent.voyage_number.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"shipping_agent", :value=>@parent.shipping_agent.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"shipping_line", :value=>@parent.shipping_line}

    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"scan_load_bay", :value=>@parent.load_bay.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"truck_number", :value=>@parent.vehicle_number.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"seal_number", :value=>@parent.container_seal_code.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"container_number", :value=>@parent.container_code.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"container_setting", :value=>@parent.container_setting.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"temperature_rhine", :value=>@parent.container_temperature_rhine.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"temperature_rhine2", :value=>@parent.container_temperature_rhine2.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"drop_down", :name=>"stack_type_code", :value=>@parent.stack_type_code, :list => stack_types}
    field_configs[field_configs.length()] = {:type=>"drop_down", :name=>"haulier_code", :is_required=>"true", :list => hauliers, :value=>@parent.haulier_id}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"cto_consec_no", :value=>@parent.cto_consec_code}

    screen_attributes = {:auto_submit=>"true", :auto_submit_to =>"load_container_submit", :content_header_caption=>"load_container"}
    buttons = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"load_container_submit", "B1Label"=>"submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def build_update_screen
    build_default_screen
  end

  def load_container_submit
    haulier = PartiesRole.find_by_party_name(self.pdt_screen_def.get_control_value("haulier_code"))
    container_code = self.pdt_screen_def.get_control_value("container_number").to_s.strip
    container_setting = self.pdt_screen_def.get_control_value("container_setting").to_s.strip
    container_temperature_rhine = self.pdt_screen_def.get_control_value("temperature_rhine").to_s.strip
    container_temperature_rhine2 = self.pdt_screen_def.get_control_value("temperature_rhine2").to_s.strip
    load_bay =  self.pdt_screen_def.get_control_value("scan_load_bay").to_s.strip
    vehicle_number = self.pdt_screen_def.get_control_value("truck_number").to_s.strip
    cto_consec_code = self.pdt_screen_def.get_control_value("cto_consec_no").to_s.strip
    container_seal_code = self.pdt_screen_def.get_control_value("seal_number").to_s.strip
    stack_type_code =  self.pdt_screen_def.get_control_value("stack_type_code").to_s.strip

    if container_code != ""         #==> rule for container code
      load_voyage = LoadVoyage.find_by_sql("select * from load_voyages where load_id = '#{@parent.load_id}'  order by id desc")[0]
      if load_voyage == nil
        self.parent.set_active_state(nil)
        return result_screen = PDTTransaction.build_msg_screen_definition("you have not created a load voyage yet",nil,nil,nil)
       end
    end

      ActiveRecord::Base.transaction do
      load = Load.find(@parent.load_id)
      load.load_bay = load_bay
      load.set_status("TRUCK_ARRIVED")

      unless @parent.load_container_id == nil
        load_container_update = LoadContainer.find(@parent.load_container_id)
        load_container_update.container_code = container_code
        load_container_update.container_temperature_rhine = container_temperature_rhine
        load_container_update.container_temperature_rhine2 = container_temperature_rhine2
        load_container_update.container_seal_code = container_seal_code
        load_container_update.cto_consec_code = cto_consec_code
        load_container_update.stack_type_code = stack_type_code
        load_container_update.container_setting = container_setting
        load_container_update.update

      else
        if container_code != ""
          load_container = LoadContainer.new
          load_container.container_code = container_code
          load_container.container_temperature_rhine = container_temperature_rhine
          load_container.container_temperature_rhine2 = container_temperature_rhine2
          load_container.container_seal_code = container_seal_code
          load_container.cto_consec_code = cto_consec_code
          load_container.stack_type_code = stack_type_code
          load_container.load = load
          load_container.container_setting = container_setting
          load_container.create
        end
      end

      if @parent.load_vehicle_id != nil
        load_vehicle_update = LoadVehicle.find(@parent.load_vehicle_id)
        load_vehicle_update.vehicle_number = vehicle_number
        load_vehicle_update.haulier_party_id = haulier.id
        load_vehicle_update.update

      else

        load_vehicle = LoadVehicle.new
        load_vehicle.vehicle_number = vehicle_number
        load_vehicle.load = load
        load_vehicle.haulier_party_id = haulier.id
        load_vehicle.create
      end

      self.parent.set_transaction_complete_flag

      result = ["Container Loaded Successfully"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, result)
      return result_screen
       
    end
  end
end