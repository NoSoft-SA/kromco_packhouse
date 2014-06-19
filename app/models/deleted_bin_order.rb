class DeletedBinOrder < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 

 
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
#		 is_valid = ModelHelper::Validations.validate_combos([{:order_type_id => self.order_type_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_bin_order
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:order_type_code => self.order_type_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_order_type
#	 end
#end
#
##	===========================
##	 foreign key validations:
##	===========================
#def set_bin_order
#
#	bin_order = BinOrder.find_by_order_type_id(self.order_type_id)
#	 if bin_order != nil
#		 self.bin_order = bin_order
#		 return true
#	 else
#		errors.add_to_base("value of field: 'order_type_id' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_order_type
#
#	order_type = OrderType.find_by_order_type_code(self.order_type_code)
#	 if order_type != nil
#		 self.order_type = order_type
#		 return true
#	 else
#		errors.add_to_base("value of field: 'order_type_code' is invalid- it must be unique")
#		 return false
#	end
#end
#
#	===========================
#	 lookup methods:
#	===========================



end
