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
    exists = MesscadaPeripheral.find_by_code(self.code)
    if exists != nil
      errors.add_to_base("There already exists a record with the code value of fields: '#{self.code}' ")
    end
  end

  def before_save

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

  def after_save

  end

end