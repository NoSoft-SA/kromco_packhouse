class MesscadaServer < ActiveRecord::Base

  #MM122014- messcada changes
  belongs_to :messcada_facility
  has_many :messcada_clusters #, :dependent => :destroy

  # attr_accessor :facility_code

  validates_presence_of :code

  # def validate
  #   validate_uniqueness
  # end
  #
  # def validate_uniqueness
  #   exists = MesscadaServer.find_by_code(self.code)
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

    facility = MesscadaFacility.find(self.facility_id)
    self.facility_code = facility.code

  end

  def after_save

  end

end