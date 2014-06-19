class CartonsPerPallet < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :pallet_format_product
	belongs_to :carton_pack_product
 
#	============================
#	 Validations declarations:
#	============================
	
	validates_numericality_of :layers_per_pallet
	validates_numericality_of :cartons_per_pallet
	validates_numericality_of :cartons_per_layer
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:carton_pack_product_code => self.carton_pack_product_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_carton_pack_product
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:pallet_format_product_code => self.pallet_format_product_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pallet_format_product
	 end
	 
	 if is_valid
	  self.cpp_code = self.pallet_format_product_code + "_" +  self.carton_pack_product_code + "_" + self.cartons_per_pallet.to_s 
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_pallet_format_product

	pallet_format_product = PalletFormatProduct.find_by_pallet_format_product_code(self.pallet_format_product_code)
	 if pallet_format_product != nil 
		 self.pallet_format_product = pallet_format_product
		 return true
	 else
		errors.add_to_base("combination of: 'pallet_format_product_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_carton_pack_product

	carton_pack_product = CartonPackProduct.find_by_carton_pack_product_code(self.carton_pack_product_code)
	 if carton_pack_product != nil 
		 self.carton_pack_product = carton_pack_product
		 return true
	 else
		errors.add_to_base("combination of: 'carton_pack_product_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: pallet_format_product_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_pallet_format_product_codes

	pallet_format_product_codes = PalletFormatProduct.find_by_sql('select distinct pallet_format_product_code from pallet_format_products').map{|g|[g.pallet_format_product_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: carton_pack_product_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_carton_pack_product_codes

	carton_pack_product_codes = CartonPackProduct.find_by_sql('select distinct carton_pack_product_code from carton_pack_products').map{|g|[g.carton_pack_product_code]}
end






end
