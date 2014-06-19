class UnitPackProduct < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
    belongs_to :product
	belongs_to :unit_pack_product_type
	belongs_to :unit_pack_product_subtype
 
#	============================
#	 Validations declarations:
#	============================
	
#	=====================
#	 Complex validations:
#	=====================

def before_destroy
  self.product.destroy

end


def before_create
 
 product = nil
 product = Product.find_by_product_code(self.unit_pack_product_code)
  if ! product
   product = Product.new
   product.product_code = self.unit_pack_product_code
   product.product_type_code = "UNIT_PACK"
   product.product_type = ProductType.find_by_product_type_code("UNIT_PACK")
   product.create
 end
 
 self.product = product
 
end


def validate 

 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:subtype_code => self.subtype_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_unit_pack_product_subtype
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:type_code => self.type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_unit_pack_product_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
	 
	  if !self.gross_mass||self.gross_mass == 0
	    mass = "*" 
	  else
	    if self.gross_mass.round == self.gross_mass
	       mass = self.gross_mass.round.to_s
	     else
	       mass = self.gross_mass.to_s
	     end
	  end
	  
	 
	  if !self.fruit_per_ru
	    fruit_per_ru = "*"
	  else
	    fruit_per_ru = self.fruit_per_ru
	  end
	  

	   self.unit_pack_product_code = self.type_code + mass + self.subtype_code + fruit_per_ru.to_s 
      
     
end

def validate_uniqueness
	 exists = UnitPackProduct.find_by_type_code_and_subtype_code_and_gross_mass_and_fruit_per_ru(self.type_code,self.subtype_code,self.gross_mass,self.fruit_per_ru)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'type_code' and 'subtype_code' and 'gross_mass' and 'fruit_per_ru' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_unit_pack_product_type

	unit_pack_product_type = UnitPackProductType.find_by_type_code(self.type_code)
	 if unit_pack_product_type != nil 
		 self.unit_pack_product_type = unit_pack_product_type
		 return true
	 else
		errors.add_to_base("combination of: 'type_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_unit_pack_product_subtype

	unit_pack_product_subtype = UnitPackProductSubtype.find_by_subtype_code(self.subtype_code)
	 if unit_pack_product_subtype != nil 
		 self.unit_pack_product_subtype = unit_pack_product_subtype
		 return true
	 else
		errors.add_to_base("combination of: 'subtype_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: unit_pack_product_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_type_codes

	type_codes = UnitPackProductType.find_by_sql('select distinct type_code from unit_pack_product_types').map{|g|[g.type_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: unit_pack_product_subtype_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_subtype_codes

	subtype_codes = UnitPackProductSubtype.find_by_sql('select distinct subtype_code from unit_pack_product_subtypes').map{|g|[g.subtype_code]}
end






end
