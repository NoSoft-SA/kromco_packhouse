class ContactMethod < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :contact_method_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :contact_method_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:contact_method_type_code => self.contact_method_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_contact_method_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = ContactMethod.find_by_contact_method_type_code_and_contact_method_code(self.contact_method_type_code,self.contact_method_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'contact_method_type_code' and 'contact_method_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_contact_method_type

	contact_method_type = ContactMethodType.find_by_contact_method_type_code(self.contact_method_type_code)
	 if contact_method_type != nil 
		 self.contact_method_type = contact_method_type
		 return true
	 else
		errors.add_to_base("combination of: 'contact_method_type_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: contact_method_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_contact_method_type_codes

	contact_method_type_codes = ContactMethodType.find_by_sql('select distinct contact_method_type_code from contact_method_types').map{|g|[g.contact_method_type_code]}
end






end
