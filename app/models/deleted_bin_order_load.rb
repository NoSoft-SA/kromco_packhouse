class DeletedBinOrderLoad < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :deleted_bin_load

	belongs_to :deleted_bin_order
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
#def validate
##	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:status => self.status}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_bin_order_load
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:haulier_party_role_id => self.haulier_party_role_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_deleted_bin_load
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:order_type_id => self.order_type_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_deleted_bin_order
#	 end
#end
#
##	===========================
##	 foreign key validations:
##	===========================
#def set_deleted_bin_load
#
#	deleted_bin_load = DeletedBinLoad.find_by_haulier_party_role_id(self.haulier_party_role_id)
#	 if deleted_bin_load != nil
#		 self.deleted_bin_load = deleted_bin_load
#		 return true
#	 else
#		errors.add_to_base("value of field: 'haulier_party_role_id' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_bin_order_load
#
#	bin_order_load = BinOrderLoad.find_by_status(self.status)
#	 if bin_order_load != nil
#		 self.bin_order_load = bin_order_load
#		 return true
#	 else
#		errors.add_to_base("value of field: 'status' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_deleted_bin_order
#
#	deleted_bin_order = DeletedBinOrder.find_by_order_type_id(self.order_type_id)
#	 if deleted_bin_order != nil
#		 self.deleted_bin_order = deleted_bin_order
#		 return true
#	 else
#		errors.add_to_base("value of field: 'order_type_id' is invalid- it must be unique")
#		 return false
#	end
#end
#
##	===========================
##	 lookup methods:
##	===========================



end
