class Currency < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 has_many :trading_partners

 validates_presence_of :currency_code
 validates_presence_of :medium_description

 
 
#	============================
#	 Validations declarations:
#	============================
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
