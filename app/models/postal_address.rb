class PostalAddress < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :postal_address_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :address1
	
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:postal_address_type_code => self.postal_address_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_postal_address_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
	 
	 
end

def validate_uniqueness
	 exists = PostalAddress.find_by_postal_address_type_code_and_city_and_address1_and_address2(self.postal_address_type_code,self.city,self.address1,self.address2)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'postal_address_type_code' and 'city' and 'address1' and 'address2' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_postal_address_type

	postal_address_type = PostalAddressType.find_by_postal_address_type_code(self.postal_address_type_code)
	 if postal_address_type != nil 
		 self.postal_address_type = postal_address_type
		 return true
	 else
		errors.add_to_base("combination of: 'postal_address_type_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: postal_address_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_postal_address_type_codes

	postal_address_type_codes = PostalAddressType.find_by_sql('select distinct postal_address_type_code from postal_address_types').map{|g|[g.postal_address_type_code]}
end






end
