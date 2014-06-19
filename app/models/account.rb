class Account < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :account_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :account_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:account_type_name => self.account_type_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_account_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Account.find_by_account_code(self.account_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'account_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_account_type

	account_type = AccountType.find_by_account_type_name(self.account_type_name)
	 if account_type != nil 
		 self.account_type = account_type
		 return true
	 else
		errors.add_to_base("value of field: 'account_type_name' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
