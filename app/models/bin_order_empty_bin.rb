class BinOrderEmptyBin < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :bin_order
	belongs_to :pack_material_product
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:id => self.id}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_bin_order
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pack_material_product
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_bin_order

	bin_order = BinOrder.find_by_id(self.id)
	 if bin_order != nil 
		 self.bin_order = bin_order
		 return true
	 else
		errors.add_to_base("value of field: 'id' is invalid- it must be unique")
		 return false
	end
end
 
def set_pack_material_product

	pack_material_product = PackMaterialProduct.find_by_pack_material_product_code(self.pack_material_product_code)
	 if pack_material_product != nil 
		 self.pack_material_product = pack_material_product
		 return true
	 else
		errors.add_to_base("combination of: 'pack_material_product_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: pack_material_products_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_pack_material_product_codes

	pack_material_product_codes = PackMaterialProduct.find_by_sql('select distinct pack_material_product_code from pack_material_products').map{|g|[g.pack_material_product_code]}
end






end
