
class RecordContainer < PDTTransactionState
  attr_accessor  :next_state


def initialize(parent)
  self.parent = parent

end

  #======= build default screen =========
  def build_default_screen

    hauliers = PartiesRole.find_by_sql("SELECT party_type_name,role_name,party_name FROM parties_roles WHERE parties_roles.party_type_name = 'ORGANIZATION' and parties_roles.role_name = 'HAULIER'").map{|g|g.party_name}.join(",")
    hauliers = ", ," + hauliers

    field_configs = Array.new
    field_configs[field_configs.length()] = {:type=>"static_text",:name=>"load_number",:value=>@parent.load_number.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text",:name=>"booking_reference",:value=>@parent.booking_reference.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text",:name=>"vessel_name",:value=>@parent.vessel_name.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text",:name=>"voyage_number",:value=>@parent.voyage_number.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text",:name=>"shipping_agent",:value=>@parent.shipping_agent.to_s}
    field_configs[field_configs.length()] = {:type=>"static_text",:name=>"shipping_line",:value=>@parent.shipping_line}
    field_configs[field_configs.length()] = {:type=>"static_text",:name=>"discharge_port",:value=>@parent.discharge_port}
    field_configs[field_configs.length()] = {:type=>"static_text",:name=>"quay_of_discharge_port",:value=>@parent.quay_of_discharge_port.to_s}
    field_configs[field_configs.length()] = {:type=>"text_box",:name=>"scan_load_bay",:is_required=>"true"}
    field_configs[field_configs.length()] = {:type=>"text_box",:name=>"truck_number",:is_required=>"true"}
    field_configs[field_configs.length()] = {:type=>"text_box",:name=>"seal_number",:is_required=>"true"}
    field_configs[field_configs.length()] = {:type=>"text_box",:name=>"container_number",:is_required=>"true"}
    field_configs[field_configs.length()] = {:type=>"text_box",:name=>"temperature_rhine",:is_required=>"true"}
    field_configs[field_configs.length()] = {:type=>"text_box",:name=>"temperature_rhine2",:is_required=>"true"}
    field_configs[field_configs.length()] = {:type=>"drop_down",:name=>"haulier_code",:is_required=>"true", :list => hauliers, :value =>'haulier_party_role_id'}
    field_configs[field_configs.length()] = {:type=>"text_box",:name=>"container_size",:is_required=>"true"}
    field_configs[field_configs.length()] = {:type=>"text_box",:name=>"cto_consec_no",:is_required=>"false"}


    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"load_container"}
    buttons = {"B3Label"=>"" ,"B2Label"=>"","B1Submit"=>"load_container_submit","B1Label"=>"submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

#======SET STATUS=======
   def set_status(new_status)
     load = Load.new
     load.load_status = new_status
     load.save
     load_status = new_status
   end


  #==================  load container submit ==================
  def load_container_submit

       haulier = PartiesRole.find_by_party_name(self.pdt_screen_def.get_control_value("haulier_code"))
       container_code = self.pdt_screen_def.get_control_value("container_number").to_s.strip
       container_temperature_rhine = self.pdt_screen_def.get_control_value("temperature_rhine").to_s.strip
       container_temperature_rhine2 = self.pdt_screen_def.get_control_value("temperature_rhine2").to_s.strip
       load_bay =  self.pdt_screen_def.get_control_value("scan_load_bay").to_s.strip
       vehicle_number = self.pdt_screen_def.get_control_value("truck_number").to_s.strip
       cto_consec_code = self.pdt_screen_def.get_control_value("cto_consec_no").to_s.strip
       stack_type_code = self.pdt_screen_def.get_control_value("container_size").to_s.strip
       container_seal_code = self.pdt_screen_def.get_control_value("seal_number").to_s.strip


        ActiveRecord::Base.transaction do

       load = Load.new
       load.load_bay =  load_bay
       load.load_status = set_status("CTO_CAPTURED")

       if self.pdt_screen_def.get_control_value("cto_consec_no").to_s.strip != ""
         load.load_status = set_status("TRUCK_ARRIVED")
       end

       load.create

       load_container = LoadContainer.new
       load_container.container_code = container_code
       load_container.container_temperature_rhine = container_temperature_rhine
       load_container.container_temperature_rhine2 = container_temperature_rhine2
       load_container.container_seal_code = container_seal_code
       load_container.stack_type_code = stack_type_code
       load_container.cto_consec_code = cto_consec_code
       load_container.load = load
       load_container.haulier_party_id = haulier.id
       load_container.create


       #======== create new vehicle ===========
       load_vehicle = LoadVehicle.new
       load_vehicle.vehicle_number = vehicle_number
       load_vehicle.load =  load
       load_vehicle.create

    self.parent.set_transaction_complete_flag
    result = ["Container Loaded Successfully"]
    result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,result)
    return result_screen
       end
    end


end