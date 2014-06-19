class FarmsReal < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :farm_group
	belongs_to :parties_role
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :farm_code
	validates_numericality_of :max_empty_bins
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:farm_group_code => self.farm_group_code},{:id => self.id}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_farm_group
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:party_type_name => self.party_type_name},{:party_name => self.party_name},{:role_name => self.role_name},{:id => self.id}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_parties_role
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = FarmsReal.find_by_id_and_farm_code(self.id,self.farm_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'id' and 'farm_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_farm_group

	farm_group = FarmGroup.find_by_farm_group_code_and_id(self.farm_group_code,self.id)
	 if farm_group != nil 
		 self.farm_group = farm_group
		 return true
	 else
		errors.add_to_base("combination of: 'farm_group_code' and 'id'  is invalid- it must be unique")
		 return false
	end
end
 
def set_parties_role

	parties_role = PartiesRole.find_by_party_type_name_and_party_name_and_role_name_and_id(self.party_type_name,self.party_name,self.role_name,self.id)
	 if parties_role != nil 
		 self.parties_role = parties_role
		 return true
	 else
		errors.add_to_base("combination of: 'party_type_name' and 'party_name' and 'role_name' and 'id'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: farm_group_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_farm_group_codes

	farm_group_codes = FarmGroup.find_by_sql('select distinct farm_group_code from farm_groups').map{|g|[g.farm_group_code]}
end



def self.get_all_ids

	ids = FarmGroup.find_by_sql('select distinct id from farm_groups').map{|g|[g.id]}
end



def self.ids_for_farm_group_code(farm_group_code)

	ids = FarmGroup.find_by_sql("Select distinct id from farm_groups where farm_group_code = '#{farm_group_code}'").map{|g|[g.id]}

	ids.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: parties_role_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_party_type_names

	party_type_names = PartiesRole.find_by_sql('select distinct party_type_name from parties_roles').map{|g|[g.party_type_name]}
end



def self.get_all_party_names

	party_names = PartiesRole.find_by_sql('select distinct party_name from parties_roles').map{|g|[g.party_name]}
end



def self.party_names_for_party_type_name(party_type_name)

	party_names = PartiesRole.find_by_sql("Select distinct party_name from parties_roles where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}

	party_names.unshift("<empty>")
 end



def self.get_all_role_names

	role_names = PartiesRole.find_by_sql('select distinct role_name from parties_roles').map{|g|[g.role_name]}
end



def self.role_names_for_party_name_and_party_type_name(party_name, party_type_name)

	role_names = PartiesRole.find_by_sql("Select distinct role_name from parties_roles where party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.role_name]}

	role_names.unshift("<empty>")
 end



def self.get_all_ids

	ids = PartiesRole.find_by_sql('select distinct id from parties_roles').map{|g|[g.id]}
end



def self.ids_for_role_name_and_party_name_and_party_type_name(role_name, party_name, party_type_name)

	ids = PartiesRole.find_by_sql("Select distinct id from parties_roles where role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.id]}

	ids.unshift("<empty>")
 end






end
