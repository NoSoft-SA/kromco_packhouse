class Grade < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================

  #MM072014
  has_many :carton_presort_conversions#, :dependent => :destroy
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :grade_code
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
	 exists = Grade.find_by_grade_code(self.grade_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'grade_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
