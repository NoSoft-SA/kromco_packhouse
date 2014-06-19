class TreatmentType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :treatment_type_code
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
	 exists = TreatmentType.find_by_treatment_type_code(self.treatment_type_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'treatment_type_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
