class InventoryType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :pack_material_product
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :pack_material_sub_types
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code},{:id => self.id}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pack_material_product
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_pack_material_product

	pack_material_product = PackMaterialProduct.find_by_pack_material_product_code_and_id(self.pack_material_product_code,self.id)
	 if pack_material_product != nil 
		 self.pack_material_product = pack_material_product
		 return true
	 else
		errors.add_to_base("combination of: 'pack_material_product_code' and 'id'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: pack_material_product_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_pack_material_product_codes

	pack_material_product_codes = PackMaterialProduct.find_by_sql('select distinct pack_material_product_code from pack_material_products').map{|g|[g.pack_material_product_code]}
end



def self.get_all_ids

	ids = PackMaterialProduct.find_by_sql('select distinct id from pack_material_products').map{|g|[g.id]}
end



def self.ids_for_pack_material_product_code(pack_material_product_code)

	ids = PackMaterialProduct.find_by_sql("Select distinct id from pack_material_products where pack_material_product_code = '#{pack_material_product_code}'").map{|g|[g.id]}

	ids.unshift("<empty>")
 end






end
