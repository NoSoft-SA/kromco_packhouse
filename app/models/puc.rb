class Puc < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :puc_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :puc_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:puc_type_code => self.puc_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_puc_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Puc.find_by_puc_type_code_and_puc_code(self.puc_type_code,self.puc_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'puc_type_code' and 'puc_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_puc_type

	puc_type = PucType.find_by_puc_type_code(self.puc_type_code)
	 if puc_type != nil 
		 self.puc_type = puc_type
		 return true
	 else
		errors.add_to_base("combination of: 'puc_type_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: puc_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_puc_type_codes

	puc_type_codes = PucType.find_by_sql('select distinct puc_type_code from puc_types').map{|g|[g.puc_type_code]}
end






end
