class PartiesRole < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :role
	belongs_to :party
  has_many :trading_partners

#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:role_name => self.role_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_role
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
	 exists = PartiesRole.find_by_party_type_name_and_party_name_and_role_name(self.party_type_name,self.party_name,self.role_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'party_type_name' and 'party_name' and 'role_name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_role

	role = Role.find_by_role_name(self.role_name)
	 if role != nil 
		 self.role = role
		 return true
	 else
		errors.add_to_base("combination of: 'role_name'  is invalid- it must be unique")
		 return false
	end
end
 
def set_party

	party = Party.find_by_party_type_name_and_party_name(self.party_type_name,self.party_name)
	 if party != nil 
		 self.party = party
		 return true
	 else
		errors.add_to_base("Party does not exist")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: role_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_role_names

	role_names = Role.find_by_sql('select distinct role_name from roles').map{|g|[g.role_name]}
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
