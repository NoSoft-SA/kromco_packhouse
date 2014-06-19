class ContactMethodsParty < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :contact_method
	belongs_to :party
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :party_name
	validates_presence_of :contact_method_code
	validates_presence_of :from_date
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:contact_method_type_code => self.contact_method_type_code},{:contact_method_code => self.contact_method_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_contact_method
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:party_type_name => self.party_type_name},{:party_name => self.party_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_party
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = ContactMethodsParty.find_by_party_type_name_and_party_name_and_contact_method_type_code_and_contact_method_code(self.party_type_name,self.party_name,self.contact_method_type_code,self.contact_method_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'party_type_name' and 'party_name' and 'contact_method_type_code' and 'contact_method_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_contact_method

	contact_method = ContactMethod.find_by_contact_method_type_code_and_contact_method_code(self.contact_method_type_code,self.contact_method_code)
	 if contact_method != nil 
		 self.contact_method = contact_method
		 return true
	 else
		errors.add_to_base("combination of: 'contact_method_type_code' and 'contact_method_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_party

	party = Party.find_by_party_type_name_and_party_name(self.party_type_name,self.party_name)
	 if party != nil 
		 self.party = party
		 return true
	 else
		errors.add_to_base("combination of: 'party_type_name' and 'party_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: contact_method_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_contact_method_type_codes

	contact_method_type_codes = ContactMethod.find_by_sql('select distinct contact_method_type_code from contact_methods').map{|g|[g.contact_method_type_code]}
end



def self.get_all_contact_method_codes

	contact_method_codes = ContactMethod.find_by_sql('select distinct contact_method_code from contact_methods').map{|g|[g.contact_method_code]}
end



def self.contact_method_codes_for_contact_method_type_code(contact_method_type_code)

	contact_method_codes = ContactMethod.find_by_sql("Select distinct contact_method_code from contact_methods where contact_method_type_code = '#{contact_method_type_code}'").map{|g|[g.contact_method_code]}

	contact_method_codes.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: party_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_party_type_names

	party_type_names = Party.find_by_sql('select distinct party_type_name from parties').map{|g|[g.party_type_name]}
end



def self.get_all_party_names

	party_names = Party.find_by_sql('select distinct party_name from parties').map{|g|[g.party_name]}
end



def self.party_names_for_party_type_name(party_type_name)

	party_names = Party.find_by_sql("Select distinct party_name from parties where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}

	party_names.unshift("<empty>")
 end






end
