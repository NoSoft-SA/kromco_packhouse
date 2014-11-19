class Treatment < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :treatment_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :treatment_type_code
	validates_presence_of :treatment_code
  #MM072014
  has_many :carton_presort_conversions#, :dependent => :destroy
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:treatment_type_code => self.treatment_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_treatment_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Treatment.find_by_treatment_type_code_and_treatment_code(self.treatment_type_code,self.treatment_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'treatment_type_code' and 'treatment_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_treatment_type

	treatment_type = TreatmentType.find_by_treatment_type_code(self.treatment_type_code)
	 if treatment_type != nil 
		 self.treatment_type = treatment_type
		 return true
	 else
		errors.add_to_base("combination of: 'treatment_type_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: treatment_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_treatment_type_codes

	treatment_type_codes = TreatmentType.find_by_sql('select distinct treatment_type_code from treatment_types').map{|g|[g.treatment_type_code]}
end






end
