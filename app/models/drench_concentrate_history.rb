class DrenchConcentrateHistory < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :drench_concentrate
	belongs_to :concentrate_product
	belongs_to :drench_station
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :concentrate_quantity
#	=====================
#	 Complex validations:
#	=====================
#def validate 
##	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:drench_line_type_code => self.drench_line_type_code}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_drench_station
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:drench_station_id => self.drench_station_id}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_drench_concentrate
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:concentrate_code => self.concentrate_code}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_concentrate_product
#	 end
#end
#
##	===========================
##	 foreign key validations:
##	===========================
#def set_drench_concentrate
#
#	drench_concentrate = DrenchConcentrate.find_by_drench_station_id(self.drench_station_id)
#	 if drench_concentrate != nil 
#		 self.drench_concentrate = drench_concentrate
#		 return true
#	 else
#		errors.add_to_base("value of field: 'drench_station_id' is invalid- it must be unique")
#		 return false
#	end
#end
# 
#def set_concentrate_product
#
#	concentrate_product = ConcentrateProduct.find_by_concentrate_code(self.concentrate_code)
#	 if concentrate_product != nil 
#		 self.concentrate_product = concentrate_product
#		 return true
#	 else
#		errors.add_to_base("value of field: 'concentrate_code' is invalid- it must be unique")
#		 return false
#	end
#end
# 
#def set_drench_station
#
#	drench_station = DrenchStation.find_by_drench_line_type_code(self.drench_line_type_code)
#	 if drench_station != nil 
#		 self.drench_station = drench_station
#		 return true
#	 else
#		errors.add_to_base("value of field: 'drench_line_type_code' is invalid- it must be unique")
#		 return false
#	end
#end
# 
#	===========================
#	 lookup methods:
#	===========================



end
