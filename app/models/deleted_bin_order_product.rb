class DeletedBinOrderProduct < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 

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
#		 is_valid = ModelHelper::Validations.validate_combos([{:order_type_id => self.order_type_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_deleted_bin_order
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:required_quantity => self.required_quantity}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_bin_order_product
#	 end
#end
#
##	===========================
##	 foreign key validations:
##	===========================
#def set_bin_order_product
#
#	bin_order_product = BinOrderProduct.find_by_required_quantity(self.required_quantity)
#	 if bin_order_product != nil
#		 self.bin_order_product = bin_order_product
#		 return true
#	 else
#		errors.add_to_base("value of field: 'required_quantity' is invalid- it must be unique")
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
#	===========================
#	 lookup methods:
#	===========================



end
