class InspectionType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :grade
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :inspection_type_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:grade_code => self.grade_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_grade
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = InspectionType.find_by_inspection_type_code_and_grade_code(self.inspection_type_code,self.grade_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'inspection_type_code' and 'grade_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_grade

	grade = Grade.find_by_grade_code(self.grade_code)
	 if grade != nil 
		 self.grade = grade
		 return true
	 else
		errors.add_to_base("combination of: 'grade_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: grade_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_grade_codes

	grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map{|g|[g.grade_code]}
end






end
