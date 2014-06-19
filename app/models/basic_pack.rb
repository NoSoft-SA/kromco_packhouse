class BasicPack < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :length
	validates_numericality_of :height
	validates_numericality_of :width
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
	 exists = BasicPack.find_by_basic_pack_code(self.basic_pack_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'basic_pack_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
