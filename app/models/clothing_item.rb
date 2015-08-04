class ClothingItem < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :clothing_transaction_type
	belongs_to :clothable_person
	belongs_to :clothing_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :created_on
	validates_numericality_of :clothing_transaction_quantity
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:clothing_transaction_type_code => self.clothing_transaction_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_clothing_transaction_type
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:clothing_type_code => self.clothing_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_clothing_type
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:clock_code => self.clock_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_clothable_person
	 end
	#validates uniqueness for this record
#	 if self.new_record? && is_valid
#		 validate_uniqueness
#	 end
end

def validate_uniqueness
	 exists = ClothingItem.find_by_clothing_transaction_type_id(self.clothing_transaction_type_id)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'clothing_transaction_type_id' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_clothing_transaction_type

	clothing_transaction_type = ClothingTransactionType.find_by_clothing_transaction_type_code(self.clothing_transaction_type_code)
	 if clothing_transaction_type != nil 
		 self.clothing_transaction_type = clothing_transaction_type
		 return true
	 else
		errors.add_to_base("combination of: 'clothing_transaction_type_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_clothable_person

	clothable_person = ClothablePerson.find_by_clock_code(self.clock_code)
	 if clothable_person != nil 
		 self.clothable_person = clothable_person
		 return true
	 else
		errors.add_to_base("combination of: 'clock_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_clothing_type

	clothing_type = ClothingType.find_by_clothing_type_code(self.clothing_type_code)
	 if clothing_type != nil 
		 self.clothing_type = clothing_type
		 return true
	 else
		errors.add_to_base("combination of: 'clothing_type_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: clothing_transaction_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_clothing_transaction_type_codes

	clothing_transaction_type_codes = ClothingTransactionType.find_by_sql('select distinct clothing_transaction_type_code from clothing_transaction_types').map{|g|[g.clothing_transaction_type_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: clothable_person_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_clock_codes

	clock_codes = ClothablePerson.find_by_sql('select distinct clock_code from clothable_people').map{|g|[g.clock_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: clothing_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_clothing_type_codes

	clothing_type_codes = ClothingType.find_by_sql('select distinct clothing_type_code from clothing_types').map{|g|[g.clothing_type_code]}
end






end
