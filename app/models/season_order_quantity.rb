class SeasonOrderQuantity < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :quantity_produced
	validates_numericality_of :quantity_required
#	=====================
#	 Complex validations:
#	=====================
def validate 
#validates that quantity_required is greater than 1
    errors.add(:quantity_required, "should be at least 1" ) if quantity_required.nil? || quantity_required < 1
#	first check whether combo fields have been selected
	 is_valid = true
#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end



def validate_uniqueness
	 exists = SeasonOrderQuantity.find_by_season_code_and_customer_order_number(self.season_code,self.customer_order_number)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'season_code' and 'customer_order_number' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
