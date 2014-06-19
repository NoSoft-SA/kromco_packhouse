class DeletedBinOrderLoadDetail < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 

	belongs_to :deleted_bin_order_load

	belongs_to :deleted_bin_order_product
 
#	============================
#	 Validations declarations:
#	============================
#	validates_numericality_of :required_quantity
##	=====================
##	 Complex validations:
##	=====================
#def validate
##	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:tipped_date_time => self.tipped_date_time}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_deleted_bin_orders_bin
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:required_quantity => self.required_quantity}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_deleted_bin_order_product
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:bin_order_product_id => self.bin_order_product_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_bin_order_load_detail
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:status => self.status}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_deleted_bin_order_load
#	 end
#end
#
##	===========================
##	 foreign key validations:
##	===========================
#def set_deleted_bin_orders_bin
#
#	deleted_bin_orders_bin = DeletedBinOrdersBin.find_by_tipped_date_time(self.tipped_date_time)
#	 if deleted_bin_orders_bin != nil
#		 self.deleted_bin_orders_bin = deleted_bin_orders_bin
#		 return true
#	 else
#		errors.add_to_base("value of field: 'tipped_date_time' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_deleted_bin_order_load
#
#	deleted_bin_order_load = DeletedBinOrderLoad.find_by_status(self.status)
#	 if deleted_bin_order_load != nil
#		 self.deleted_bin_order_load = deleted_bin_order_load
#		 return true
#	 else
#		errors.add_to_base("value of field: 'status' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_bin_order_load_detail
#
#	bin_order_load_detail = BinOrderLoadDetail.find_by_bin_order_product_id(self.bin_order_product_id)
#	 if bin_order_load_detail != nil
#		 self.bin_order_load_detail = bin_order_load_detail
#		 return true
#	 else
#		errors.add_to_base("value of field: 'bin_order_product_id' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_deleted_bin_order_product
#
#	deleted_bin_order_product = DeletedBinOrderProduct.find_by_required_quantity(self.required_quantity)
#	 if deleted_bin_order_product != nil
#		 self.deleted_bin_order_product = deleted_bin_order_product
#		 return true
#	 else
#		errors.add_to_base("value of field: 'required_quantity' is invalid- it must be unique")
#		 return false
#	end
#end
 
#	===========================
#	 lookup methods:
#	===========================



end
