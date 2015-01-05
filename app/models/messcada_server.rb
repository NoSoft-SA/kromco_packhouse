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
    exists = MesscadaServer.find_by_code(self.code)
    if exists != nil
      errors.add_to_base("There already exists a record with the code value of fields: '#{self.code}' ")
    end
  end

  def before_save

    facility = MesscadaFacility.find(self.facility_id)
    self.facility_code = facility.code

  end

  def after_save

  end

end