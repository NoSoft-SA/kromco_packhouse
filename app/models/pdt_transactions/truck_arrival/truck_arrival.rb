class TruckArrival < PDTTransaction
  attr_accessor :load_number ,:voyage_number,:shipping_agent,:shipping_line,:booking_reference,:vessel_code,:voyage_id,:voyage_number,:cto_consec_code_load,
                :discharge_port,:quay_of_discharge_port ,:load_id,:load_vehicle_id,:load_container_id,:container_seal_code,:load_bay,:container_setting,
                :container_temperature_rhine,:container_temperature_rhine2,:container_code,:cto_consec_code,:stack_type_code,:vehicle_number,:haulier_id,:order_id
                                                                                        
  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_pick_list",:is_required=>"true", :scan_field => true, :submit_form => true}

    screen_attributes = {:auto_submit=>"true",:auto_submit_to => "scan_pick_list_submit",:content_header_caption=>"scan_pick_list"}
    buttons = {"B3Label"=>"" ,"B2Label"=>"","B1Submit"=>"scan_pick_list_submit","B1Label"=>"submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def scan_pick_list
    build_default_screen
  end
  
  def  scan_pick_list_submit
       load_order_id_entered = self.pdt_screen_def.get_control_value("scan_pick_list").strip
       load_record = Load.find_by_sql("select loads.load_number,loads.id,pick_list_printed_date from loads join load_orders on loads.id = load_orders.load_id where load_orders.id ='#{load_order_id_entered}' order by loads.id desc ")[0]



      if load_record == nil
      return result_screen = PDTTransaction.build_msg_screen_definition("load order id does not exists ",nil,nil,nil)
      else
        @load_number = load_record.load_number
      end

       @order_id = LoadOrder.find(load_order_id_entered.to_i).order_id

       if load_record.pick_list_printed_date ==nil
        load_record.pick_list_printed_date=Time.now.to_formatted_s(:db)
        load_record.update
      end

       @shipping_agent = ""
       
       @load_id = load_record.id
       agent = Load.find_by_sql("select party_name,shipping_agent_party_role_id from loads LEFT OUTER JOIN load_voyages ON (loads.id = load_voyages.load_id) LEFT OUTER JOIN parties_roles on (load_voyages.shipping_agent_party_role_id  = parties_roles.id ) where loads.id = load_voyages.load_id and parties_roles.role_name = 'SHIPPING AGENT' and loads.id = #{load_record.id.to_s} ORDER BY loads.id DESC ")[0]
       @shipping_agent = agent.attributes['party_name'] if agent

       @shipping_line = ""
       ship = Load.find_by_sql("select party_name,shipping_line_party_id from loads LEFT OUTER JOIN load_voyages ON (loads.id = load_voyages.load_id) LEFT OUTER JOIN parties_roles on (load_voyages.shipping_line_party_id  = parties_roles.id ) where loads.id = load_voyages.load_id and parties_roles.role_name = 'SHIPPING LINE' and loads.id = #{load_record.id.to_s} ORDER BY loads.id DESC  ")[0]
       @shipping_line = ship.attributes['party_name'] if ship

       @customer_reference = ""
       customer = Load.find_by_sql("select customer_reference from loads LEFT OUTER JOIN load_voyages ON (loads.id = load_voyages.load_id) where load_number = '#{load_record.load_number}' ORDER BY loads.id DESC ")[0]
       @customer_reference  = customer.attributes['customer_reference'] if customer

       @booking_reference = ""
       booking = Load.find_by_sql("select booking_reference from loads LEFT OUTER JOIN load_voyages ON (loads.id = load_voyages.load_id) where load_number = '#{load_record.load_number}' ORDER BY loads.id DESC ")[0]
       @booking_reference = booking.attributes['booking_reference']  if booking

       @vessel_code = ""

       vessel = Voyage.find_by_sql("select vessel_code from voyages LEFT OUTER JOIN load_voyages ON (voyages.id = load_voyages.voyage_id) where load_voyages.load_id = #{load_record.id.to_s} ORDER BY voyages.id DESC")[0]
       @vessel_code = vessel.attributes['vessel_code'] if vessel

       @voyage_number = ""
       voyage =  Voyage.find_by_sql("select voyage_number from voyages LEFT OUTER JOIN load_voyages ON (voyages.id = load_voyages.voyage_id) where load_voyages.load_id = #{load_record.id.to_s} ORDER BY voyages.id DESC ")[0]
       @voyage_number = voyage.attributes['voyage_number']  if voyage

       load_vehicle_record = LoadVehicle.find_by_sql("select * from load_vehicles where load_id = '#{@load_id.to_i}'order by id desc ")[0]
        if load_vehicle_record != nil

          @load_vehicle_id = load_vehicle_record.id.to_i
          @vehicle_number = load_vehicle_record.vehicle_number
          haulier_party_id = load_vehicle_record.haulier_party_id
          hauliers = PartiesRole.find_by_sql("SELECT * FROM parties_roles WHERE id = '#{haulier_party_id}' ")[0]
          @haulier_id = hauliers.party_name
       end

       load_container_record = LoadContainer.find_by_sql("SELECT * from load_containers where load_id = '#{@load_id.to_i}' order by id desc ")[0]
       if load_container_record == nil
         next_stage_load_containers
       else
       @load_container_id = load_container_record.id.to_i
       @container_temperature_rhine = load_container_record.container_temperature_rhine
       @container_temperature_rhine2 = load_container_record.container_temperature_rhine2
       @container_code = load_container_record.container_code
       @cto_consec_code = load_container_record.cto_consec_code
       @stack_type_code = load_container_record.stack_type_code
       @container_seal_code = load_container_record.container_seal_code
       @container_code = load_container_record.container_code
       @container_setting = load_container_record.container_setting

       load_vehicle_record = LoadVehicle.find_by_sql("select * from load_vehicles where load_id = '#{@load_id.to_i}'order by id desc ")[0]
       if load_vehicle_record != nil
       @load_vehicle_id = load_vehicle_record.id.to_i
       @vehicle_number = load_vehicle_record.vehicle_number
       haulier_party_id = load_vehicle_record.haulier_party_id

       hauliers = PartiesRole.find_by_sql("SELECT * FROM parties_roles WHERE id = '#{haulier_party_id}' ")[0]
       @haulier_id = hauliers.party_name     

       load = Load.find(@load_id)
       @cto_consec_code_load = load.load_status
       @load_bay = load.load_bay
       end

        next_stage_load_containers
       end
     end

  def next_stage_load_containers
    next_state = CaptureContainer.new(self)
    self.set_active_state(next_state)
     return next_state.build_default_screen
  end


end
