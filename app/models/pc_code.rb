class PcCode < ActiveRecord::Base 
	
	
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :pc_code
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
	 exists = PcCode.find_by_pc_code(self.pc_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'pc_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
