class AccountType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
#
#	============================
#	 Validations declarations:
#	============================
     validates_presence_of :account_type_name
     
#
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = AccountType.find_by_account_type_name(self.account_type_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'account_type_name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
