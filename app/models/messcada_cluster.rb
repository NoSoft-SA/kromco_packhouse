class MesscadaCluster < ActiveRecord::Base

  #MM122014 - messcada changes
  belongs_to :messcada_server
  has_many :messcada_modules #, :dependent => :destroy

  validates_presence_of :code, :desc_short

  def validate
    if self.new_record?
      validate_uniqueness
    end
  end

  def validate_uniqueness
    exists = MesscadaCluster.find_by_code(self.code)
    if exists != nil
      errors.add_to_base("There already exists a record with the code value of fields: '#{self.code}' ")
    end
  end

  def before_save
    server = MesscadaServer.find(self.server_id)
    self.server_code = server.code
    facility_id = server.facility_id

    facility = MesscadaFacility.find(facility_id)
    self.facility_code = facility.code

  end

  def after_save

  end

  def destroy_modules
    modules = MesscadaModule.find_by_cluster_id(self.id)
    modules.destroy_peripherals if modules !=nil
    modules.destroy if modules !=nil
  end
end