class StockType < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================
    has_many :stock_items
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :stock_type_code
	validates_uniqueness_of :stock_type_code
	
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