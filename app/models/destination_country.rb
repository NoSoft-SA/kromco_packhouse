class DestinationCountry < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :destination_country_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = DestinationCountry.find_by_destination_country_code(self.destination_country_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'destination_country_code' ")
	end
end


end
