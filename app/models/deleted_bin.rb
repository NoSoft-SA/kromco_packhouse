class DeletedBin < ActiveRecord::Base

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
#		 is_valid = ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_pack_material_product
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:rmt_product_code => self.rmt_product_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_rmt_product
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:farm_code => self.farm_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_farm
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:shift_code => self.shift_code},{:line_code => self.line_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_shift
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:tipped_date_time => self.tipped_date_time}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_bin
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:deleted_bin_order_product_id => self.deleted_bin_order_product_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_deleted_bin_order_load_detail
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:delivery_number => self.delivery_number}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_delivery
#	 end
#end
#
##	===========================
##	 foreign key validations:
##	===========================
#def set_pack_material_product
#
#	pack_material_product = PackMaterialProduct.find_by_pack_material_product_code(self.pack_material_product_code)
#	 if pack_material_product != nil
#		 self.pack_material_product = pack_material_product
#		 return true
#	 else
#		errors.add_to_base("combination of: 'pack_material_product_code'  is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_bin
#
#	bin = Bin.find_by_tipped_date_time(self.tipped_date_time)
#	 if bin != nil
#		 self.bin = bin
#		 return true
#	 else
#		errors.add_to_base("value of field: 'tipped_date_time' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_deleted_bin_order_load_detail
#
#	deleted_bin_order_load_detail = DeletedBinOrderLoadDetail.find_by_deleted_bin_order_product_id(self.deleted_bin_order_product_id)
#	 if deleted_bin_order_load_detail != nil
#		 self.deleted_bin_order_load_detail = deleted_bin_order_load_detail
#		 return true
#	 else
#		errors.add_to_base("value of field: 'deleted_bin_order_product_id' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_shift
#
#	shift = Shift.find_by_shift_code_and_line_code(self.shift_code,self.line_code)
#	 if shift != nil
#		 self.shift = shift
#		 return true
#	 else
#		errors.add_to_base("combination of: 'shift_code' and 'line_code'  is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_farm
#
#	farm = Farm.find_by_farm_code(self.farm_code)
#	 if farm != nil
#		 self.farm = farm
#		 return true
#	 else
#		errors.add_to_base("combination of: 'farm_code'  is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_rmt_product
#
#	rmt_product = RmtProduct.find_by_rmt_product_code(self.rmt_product_code)
#	 if rmt_product != nil
#		 self.rmt_product = rmt_product
#		 return true
#	 else
#		errors.add_to_base("combination of: 'rmt_product_code'  is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_delivery
#
#	delivery = Delivery.find_by_delivery_number(self.delivery_number)
#	 if delivery != nil
#		 self.delivery = delivery
#		 return true
#	 else
#		errors.add_to_base("combination of: 'delivery_number'  is invalid- it must be unique")
#		 return false
#	end
#end
#
##	===========================
##	 lookup methods:
##	===========================
##	------------------------------------------------------------------------------------------
##	Lookup methods for the foreign composite key of id field: pack_material_product_id
##	------------------------------------------------------------------------------------------
#
#def self.get_all_pack_material_product_codes
#
#	pack_material_product_codes = PackMaterialProduct.find_by_sql('select distinct pack_material_product_code from pack_material_products').map{|g|[g.pack_material_product_code]}
#end
#
#
#
##	------------------------------------------------------------------------------------------
##	Lookup methods for the foreign composite key of id field: shift_id
##	------------------------------------------------------------------------------------------
#
#def self.get_all_shift_codes
#
#	shift_codes = Shift.find_by_sql('select distinct shift_code from shifts').map{|g|[g.shift_code]}
#end
#
#
#
#def self.get_all_line_codes
#
#	line_codes = Shift.find_by_sql('select distinct line_code from shifts').map{|g|[g.line_code]}
#end
#
#
#
#def self.line_codes_for_shift_code(shift_code)
#
#	line_codes = Shift.find_by_sql("Select distinct line_code from shifts where shift_code = '#{shift_code}'").map{|g|[g.line_code]}
#
#	line_codes.unshift("<empty>")
# end
#
#
#
##	------------------------------------------------------------------------------------------
##	Lookup methods for the foreign composite key of id field: farm_id
##	------------------------------------------------------------------------------------------
#
#def self.get_all_farm_codes
#
#	farm_codes = Farm.find_by_sql('select distinct farm_code from farms').map{|g|[g.farm_code]}
#end
#
#
#
##	------------------------------------------------------------------------------------------
##	Lookup methods for the foreign composite key of id field: rmt_product_id
##	------------------------------------------------------------------------------------------
#
#def self.get_all_rmt_product_codes
#
#	rmt_product_codes = RmtProduct.find_by_sql('select distinct rmt_product_code from rmt_products').map{|g|[g.rmt_product_code]}
#end
#
#
#
##	------------------------------------------------------------------------------------------
##	Lookup methods for the foreign composite key of id field: delivery_id
##	------------------------------------------------------------------------------------------
#
#def self.get_all_delivery_numbers
#
#	delivery_numbers = Delivery.find_by_sql('select distinct delivery_number from deliveries').map{|g|[g.delivery_number]}
#end
#
#




end
