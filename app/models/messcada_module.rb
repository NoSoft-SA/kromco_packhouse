class MesscadaModule < ActiveRecord::Base

  #MM122014 - messcada changes
  belongs_to :messcada_cluster
  has_many :messcada_peripherals #, :dependent => :destroy

  validates_presence_of :code

  # def validate
  #   validate_uniqueness
  # end
  #
  # def validate_uniqueness
  #   exists = MesscadaModule.find_by_code(self.code)
  #   if exists != nil
  #     errors.add_to_base("There already exists a record with the code value of fields: '#{self.code}' ")
  #   end
  # end
  #
  # def unique_code_and_facilty_code
  #   if self.code && self.facilty_code
  #     val = ActiveRecord::Base.connection.select_one("select count(*) from messcada_servers where code=#{self.code} and facility_code=#{self.facility_code}")['count'].to_i
  #     if val > 0
  #       return false
  #     end
  #
  #   end
  #
  #   return true
  # end

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

end