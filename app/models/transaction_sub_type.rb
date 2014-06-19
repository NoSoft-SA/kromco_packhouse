class TransactionSubType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :transaction_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :transaction_sub_type_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
##	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:transaction_type_code => self.transaction_type_code}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_transaction_type
#	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_transaction_type

	transaction_type = TransactionType.find_by_transaction_type_code(self.transaction_type_code)
	 if transaction_type != nil 
		 self.transaction_type = transaction_type
		 return true
	 else
		errors.add_to_base("value of field: 'transaction_type_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
