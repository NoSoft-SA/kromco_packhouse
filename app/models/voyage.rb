class Voyage < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
  belongs_to :vessel
  has_many :load_voyages
  has_many :voyage_ports


#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :voyage_number
	validates_presence_of :vessel_code
   validates_uniqueness_of  :voyage_code
   #validates_uniqueness_of :voyage_number
	
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:vessel_code => self.vessel_code}],self)
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_vessel
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_vessel

	vessel = Vessel.find_by_vessel_code(self.vessel_code)
	 if vessel != nil 
		 self.vessel = vessel
		 return true
	 else
		errors.add_to_base("value of field: 'vessel_name' is invalid- it must be unique")
		 return false
	end
end

 # =========================
 # Virtual attributes
 # =========================
  def  port_type_code
    @port_type = VoyagePortType.find(self.voyage_port_type_id).voyage_port_type_code if !@port_type
    return  @port_type
  end


  def  port_code
    @port_code = Port.find(self.port_id).port_code if !@port_code
    return  @port_code

  end

end
