class AccountsPartiesRole < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :account
	belongs_to :parties_role
 
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
		 is_valid = ModelHelper::Validations.validate_combos([{:account_code => self.account_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_account
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:party_type_name => self.party_type_name},{:party_name => self.party_name},{:role_name => self.role_name}],self) 
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
	 exists = AccountsPartiesRole.find_by_party_type_name_and_party_name_and_role_name_and_account_code(self.party_type_name,self.party_name,self.role_name,self.account_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'party_type_name' and 'party_name' and 'role_name' and 'account_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_account

	account = Account.find_by_account_code(self.account_code)
	 if account != nil 
		 self.account = account
		 return true
	 else
		errors.add_to_base("combination of: 'account_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_parties_role

	parties_role = PartiesRole.find_by_party_type_name_and_party_name_and_role_name(self.party_type_name,self.party_name,self.role_name)
	 if parties_role != nil 
		 self.parties_role = parties_role
		 return true
	 else
		errors.add_to_base("combination of: 'party_type_name' and 'party_name' and 'role_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: account_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_account_codes

	account_codes = Account.find_by_sql('select distinct account_code from accounts').map{|g|[g.account_code]}
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






end
