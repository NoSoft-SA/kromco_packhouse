class LoadVehiclesProcessVar < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
  
#	============================
#	 Validations declarations:
#	============================
#	validates_numericality_of :qty_pallets_required
#	validates_numericality_of :qty_pallets_scanned
#	=====================
#	 Complex validations:
#	=====================
#def validate
##	first check whether combo fields have been selected
#	 is_valid = true
#	#validates uniqueness for this record
#	 if self.new_record? && is_valid
#		 validate_uniqueness
#	 end
#end
#
#def validate_uniqueness
#	 exists = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle_number)
#	 if exists != nil
#		errors.add_to_base("There already exists a record with the combined values of fields: 'vehicle_number' ")
#	end
#end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
