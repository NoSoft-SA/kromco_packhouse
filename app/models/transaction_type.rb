class TransactionType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
    #has_many :transaction_sub_types,:dependent => :destroy
 
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :transaction_type_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
end

#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
