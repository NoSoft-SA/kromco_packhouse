class CaptureContainer < PDTTransactionState

  def initialize(parent)
    self.parent = parent
  end

  def get_haulier_destination_rate(haulier)
    transporter_rate = TransporterRate.find(:first, :conditions=>"h.party_name='#{haulier}' and l.load_id=#{@parent.load_id} and l.order_id=#{@parent.order_id}",
                         :joins=>"join load_orders l on l.destination_city_id=transporter_rates.city_id
                                  join transporters x on x.id=transporter_rates.transporter_id
                                  join parties_roles h on h.id=x.haulier_parties_role_id")
    return transporter_rate.rate if(transporter_rate)
    return nil
  end

  def haulier_code_combo_changed
    field_configs = {:name=>'rate',:type=>'static_text',:value=> get_haulier_destination_rate(@parent.params['haulier_code']),:is_required=>'false'}

    return PdtScreenDefinition.gen_controls_list_xml(field_configs)
  end

  def build_default_screen
    if((order = Order.find(@parent.order_id)) && order.incoterm && order.incoterm.incoterm_code =='DAP')
      hauliers = PartiesRole.find(:all, :select=>'parties_roles.party_name',
                                       :joins => "join transporters t on t.haulier_parties_role_id=parties_roles.id").map { |g| g.party_name }.join(",")
      hauliers = "" + hauliers

      haulier_cascades ={:type=>'replace_control',
                                     :settings=>{:target_control_name=>'rate',:remote_method=>'haulier_code_combo_changed',:filter_fields=>'haulier_code'}}
    else
      hauliers = "OWN"
    end
    stack_types=StackType.find(:all).map{|o|o.stack_type_code}.join(",")
    stack_types = ", ," +  stack_types

    field_configs = Array.new
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"load_number", :value=>@parent.load_number.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"booking_reference", :value=>@parent.booking_reference.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"vessel_code", :value=>@parent.vessel_code.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"voyage_number", :value=>@parent.voyage_number.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"shipping_agent", :value=>@parent.shipping_agent.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"shipping_line", :value=>@parent.shipping_line}

    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"scan_load_bay", :value=>@parent.load_bay.to_s.strip, :scan_field => true}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"truck_number", :value=>@parent.vehicle_number.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"seal_number", :value=>@parent.container_seal_code.to_s.strip, :scan_field => true}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"container_number", :value=>@parent.container_code.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"container_setting", :value=>@parent.container_setting.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"temperature_rhine", :value=>@parent.container_temperature_rhine.to_s.strip, :scan_field => true}
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"temperature_rhine2", :value=>@parent.container_temperature_rhine2.to_s.strip}
    field_configs[field_configs.length()] = {:type=>"drop_down", :name=>"stack_type_code", :value=>@parent.stack_type_code, :list => stack_types,:is_required=>'true'}
    field_configs[field_configs.length()] = {:type=>"drop_down", :name=>"haulier_code", :is_required=>"true", :list => hauliers, :value=>@parent.haulier_id}
    if(haulier_cascades)
      field_configs[field_configs.length()-1].store(:cascades, haulier_cascades)
      field_configs[field_configs.length()] = {:name=>'rate',:type=>'static_text',:value=> get_haulier_destination_rate(@parent.haulier_id),:is_required=>'false'}
    end
    field_configs[field_configs.length()] = {:type=>"text_box", :name=>"cto_consec_no", :value=>@parent.cto_consec_code}

    screen_attributes = {:auto_submit=>"false",  :content_header_caption=>"load_container"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"", "B2Submit"=>"", "B1Submit"=>"load_container_submit","B1Label"=>"submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }

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
    rate =  self.pdt_screen_def.get_control_value("rate").to_s.strip

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
        load_vehicle_update.rate = rate
        load_vehicle_update.update

      else

        load_vehicle = LoadVehicle.new
        load_vehicle.vehicle_number = vehicle_number
        load_vehicle.load = load
        load_vehicle.haulier_party_id = haulier.id
        load_vehicle.rate = rate
        load_vehicle.create
      end

      self.parent.set_transaction_complete_flag

      result = ["Container Loaded Successfully"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, result)
      return result_screen
       
    end
  end
end
