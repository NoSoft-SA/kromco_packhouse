class VoyagePortType < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================

   has_many :voyage_ports
#	============================
#	 Validations declarations:
#	============================
  validates_presence_of :voyage_port_type_code
  validates_presence_of :voyage_port_type_description
  validates_uniqueness_of  :voyage_port_type_code
#	=====================
#	 Complex validations:
#	=====================
  def validate
#	first check whether combo fields have been selected
    is_valid = true
  end

#	===========================
#	 foreign key validations:
#	===========================

  def voyage_port_code
    @voyage_port_code = VoyagePortType.find(self.port_type_id).voyage_port_type_code if @voyage_port_code
    return @voyage_port_code
  end




end
