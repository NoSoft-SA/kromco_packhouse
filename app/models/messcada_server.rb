class MesscadaServer < ActiveRecord::Base

  #MM122014- messcada changes
  belongs_to :messcada_facility
  has_many :messcada_clusters #, :dependent => :destroy

  # attr_accessor :facility_code

  validates_presence_of :code,:tcp_ip,:tcp_port,:web_ip,:web_port,:desc_short

  def validate
    if self.new_record?
      validate_uniqueness
    end
  end

  def validate_uniqueness
    exists = MesscadaServer.find_by_code_and_facility_code(self.code,self.facility_code)
    if exists != nil
      errors.add_to_base("There already exists a record with the field values of code: '#{self.code}' and facility_code: '#{self.facility_code}' ")
    end
  end

  def before_save

    # facility = MesscadaFacility.find(self.facility_id)
    # self.facility_code = facility.code

  end

  def after_save

  end

  def run_before_save

    facility = MesscadaFacility.find(self.facility_id)
    self.facility_code = facility.code

  end

  def self.save_selected_messcada_servers(messcada_servers,facility_id)

    ActiveRecord::Base.transaction do
      for server in messcada_servers

        messcada_server=MesscadaServer.new()

        messcada_server.code = server.code
        messcada_server.tcp_ip = server.tcp_ip
        messcada_server.tcp_port = server.tcp_port
        messcada_server.web_ip = server.web_ip
        messcada_server.web_port = server.web_port
        messcada_server.is_active = server.is_active
        messcada_server.desc_short = server.desc_short
        messcada_server.desc_medium = server.desc_medium
        messcada_server.desc_long = server.desc_long
        # messcada_server.created_at = server.created_at
        # messcada_server.updated_at = server.updated_at

        messcada_server.facility_id=facility_id if server.facility_id !=nil
        messcada_server.run_before_save if server.facility_id !=nil

        messcada_server.save

      end
    end
    return nil
  end

  def destroy_clusters
    cluster = MesscadaCluster.find_by_server_id(self.id)
    cluster.destroy_modules if cluster !=nil
    cluster.destroy if cluster !=nil
  end

end