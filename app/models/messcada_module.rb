class MesscadaModule < ActiveRecord::Base

  #MM122014 - messcada changes
  belongs_to :messcada_cluster
  has_many :messcada_peripherals #, :dependent => :destroy

  validates_presence_of :code,:module_type_code,:module_function_type_code,:ip,:port

  def validate
    if self.new_record?
      validate_uniqueness
    end
  end

  def validate_uniqueness
    exists = MesscadaModule.find_by_code(self.code)
    if exists != nil
      errors.add_to_base("There already exists a record with the code value of fields: '#{self.code}' ")
    end
  end

  def before_save

    cluster = MesscadaCluster.find(self.cluster_id)
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

  def destroy_peripherals
    peripherals = MesscadaPeripheral.find_by_module_id(self.id)
    peripherals.destroy_peripheral_printers if peripherals !=nil
    peripherals.destroy if peripherals !=nil
  end

end