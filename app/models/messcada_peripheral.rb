class MesscadaPeripheral < ActiveRecord::Base

  #MM122014 - messcada changes
  belongs_to :messcada_module

  has_many :messcada_peripheral_printers #, :dependent => :destroy

  validates_presence_of :code,:peripheral_type_code,:peripheral_group_code,:comms_type_code,:ip,:port,:baud,
                        :databooleans,:stopboolean,:flow_control,:button_tooltip,:input_buffer_length,:output_buffer_length,
                        :timeout_milli_seconds,:device_name,:parameters,:communication_parameters,:network_parameters,
                        :dbms_parameters,:application_parameters

  def validate
    if self.new_record?
      validate_uniqueness
    end
  end

  def validate_uniqueness
    exists = MesscadaPeripheral.find_by_code_and_facility_code_and_server_code_and_cluster_code_and_module_code(self.code,self.facility_code, self.server_code, self.cluster_code, self.module_code)
    if exists != nil
      errors.add_to_base("There already exists a record with the field values of code: '#{self.code}',  facility_code: '#{facility_code}', server_code: '#{server_code}', cluster_code: '#{cluster_code}', module_code: '#{module_code}'")
    end
  end

  def before_save

    # modules = MesscadaModule.find(self.module_id)
    # self.module_code = modules.code
    # cluster_id = modules.cluster_id
    #
    # cluster = MesscadaCluster.find(cluster_id)
    # self.cluster_code = cluster.code
    # server_id = cluster.server_id
    #
    # server = MesscadaServer.find(server_id)
    # self.server_code = server.code
    # facility_id = server.facility_id
    #
    # facility = MesscadaFacility.find(facility_id)
    # self.facility_code = facility.code

  end

  def after_save

  end

  def run_before_save

    modules = MesscadaModule.find(self.module_id)
    self.module_code = modules.code
    cluster_id = modules.cluster_id

    cluster = MesscadaCluster.find(cluster_id)
    self.cluster_code = cluster.code
    server_id = cluster.server_id

    server = MesscadaServer.find(server_id)
    self.server_code = server.code
    facility_id = server.facility_id

    facility = MesscadaFacility.find(facility_id)
    self.facility_code = facility.code

  end


  def run_before_saving(messcada_peripheral,field_name,field_value)

    if field_name == "module_id"
      modules = MesscadaModule.find(field_value)
      self.module_id = field_value
      self.module_code = modules.code
      self.cluster_code =  modules.cluster_code
      self.server_code = modules.server_code
      self.facility_code = modules.facility_code

      elsif field_name == "cluster_code"
          cluster = MesscadaCluster.find_by_code(field_value)
          self.cluster_code = field_value
          self.server_code = cluster.server_code
          self.facility_code = cluster.facility_code

        elsif field_name == "server_code"
          server = MesscadaServer.find_by_code(field_value)
          self.server_code = field_value
          self.facility_code = server.facility_code

        elsif field_name == "facility_code"
          facility = MesscadaFacility.find_by_code(field_value)
          self.facility_code = field_value
        else
    end
    return messcada_peripheral
  end

  def self.save_selected_messcada_peripherals(messcada_peripherals,field_name,field_value)

    ActiveRecord::Base.transaction do
      for peripheral in messcada_peripherals

        messcada_peripheral=MesscadaPeripheral.new()

        messcada_peripheral.code = peripheral.code
        messcada_peripheral.peripheral_type_code = peripheral.peripheral_type_code
        messcada_peripheral.peripheral_group_code = peripheral.peripheral_group_code
        messcada_peripheral.is_active = peripheral.is_active
        messcada_peripheral.comms_type_code = peripheral.comms_type_code
        messcada_peripheral.ip = peripheral.ip
        messcada_peripheral.port = peripheral.port
        messcada_peripheral.baud = peripheral.baud
        messcada_peripheral.parity = peripheral.parity
        messcada_peripheral.databooleans = peripheral.databooleans
        messcada_peripheral.stopboolean = peripheral.stopboolean
        messcada_peripheral.flow_control = peripheral.flow_control
        messcada_peripheral.start_of_input = peripheral.start_of_input
        messcada_peripheral.end_of_input = peripheral.end_of_input
        messcada_peripheral.messages = peripheral.messages
        messcada_peripheral.button = peripheral.button
        messcada_peripheral.button_tooltip = peripheral.button_tooltip
        messcada_peripheral.keyboard_robot = peripheral.keyboard_robot
        messcada_peripheral.input_buffer_length = peripheral.input_buffer_length
        messcada_peripheral.output_buffer_length = peripheral.output_buffer_length
        messcada_peripheral.timeout_milli_seconds = peripheral.timeout_milli_seconds
        messcada_peripheral.device_name = peripheral.device_name
        messcada_peripheral.mac_address = peripheral.mac_address
        messcada_peripheral.parameters = peripheral.parameters
        messcada_peripheral.communication_parameters = peripheral.communication_parameters
        messcada_peripheral.network_parameters = peripheral.network_parameters
        messcada_peripheral.dbms_parameters = peripheral.dbms_parameters
        messcada_peripheral.application_parameters = peripheral.application_parameters
        # messcada_peripheral.created_at = peripheral.created_at
        # messcada_peripheral.updated_at = peripheral.updated_at

        messcada_peripheral.run_before_saving(self,field_name,field_value)
        messcada_peripheral.save

      end
    end
    return nil
  end

end