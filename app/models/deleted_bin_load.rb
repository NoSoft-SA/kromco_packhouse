class DeletedBinLoad < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 

	belongs_to :bin_load
 
##	============================
##	 Validations declarations:
##	============================
#	validates_numericality_of :vehicle_empty_mass_in
#	validates_numericality_of :tare_mass_out
#	validates_numericality_of :vehicle_full_mass_out
#	validates_numericality_of :tare_mass_in
##	=====================
##	 Complex validations:
##	=====================
#def validate
##	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:haulier_party_role_id => self.haulier_party_role_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_bin_load
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:load_type_code => self.load_type_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_load_type
#	 end
#end
#
##	===========================
##	 foreign key validations:
##	===========================
#def set_load_type
#
#	load_type = LoadType.find_by_load_type_code(self.load_type_code)
#	 if load_type != nil
#		 self.load_type = load_type
#		 return true
#	 else
#		errors.add_to_base("value of field: 'load_type_code' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_bin_load
#
#	bin_load = BinLoad.find_by_haulier_party_role_id(self.haulier_party_role_id)
#	 if bin_load != nil
#		 self.bin_load = bin_load
#		 return true
#	 else
#		errors.add_to_base("value of field: 'haulier_party_role_id' is invalid- it must be unique")
#		 return false
#	end
#end
#
##	===========================
##	 lookup methods:
##	===========================
#


end
