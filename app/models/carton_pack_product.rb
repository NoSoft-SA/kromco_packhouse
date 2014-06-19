class CartonPackProduct < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
    belongs_to :product
	belongs_to :carton_pack_style
	belongs_to :carton_pack_type
	belongs_to :basic_pack
 

#	=====================
#	 Complex validations:
#	=====================

def before_destroy
 self.product.destroy

end

 def before_create
 
  product = nil
  product =Product.find_by_product_code(self.carton_pack_product_code)
  if ! product
    product = Product.new
    product.product_code = self.carton_pack_product_code
    product.product_type_code = "CARTON_PACK"
    product.product_type = ProductType.find_by_product_type_code("CARTON_PACK")
    product.create
  
 end
 
  self.product = product
 
end




def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:type_code => self.type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_carton_pack_type
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:carton_pack_style_code => self.carton_pack_style_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_carton_pack_style
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:basic_pack_code => self.basic_pack_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_basic_pack
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
	 
	 mass = nil
	 height = nil
	 
     if !self.nett_mass||self.nett_mass == 0
	    mass = "*" 
	  else
	   mass = self.nett_mass
	  end
	  
	  if !self.height||self.height == 0 
	    height = "*"
	  else
	    height = self.height.to_s
	  end
	  
	
	  self.carton_pack_product_code = self.type_code  + self.basic_pack_code  + self.carton_pack_style_code  + height.to_s
     
end

def validate_uniqueness
	 exists = CartonPackProduct.find_by_type_code_and_basic_pack_code_and_carton_pack_style_code_and_height(self.type_code,self.basic_pack_code,self.carton_pack_style_code,self.height)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'type_code' and 'basic_pack_code' and 'carton_pack_style_code' and 'size' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_carton_pack_style

	carton_pack_style = CartonPackStyle.find_by_carton_pack_style_code(self.carton_pack_style_code)
	 if carton_pack_style != nil 
		 self.carton_pack_style = carton_pack_style
		 return true
	 else
		errors.add_to_base("value of field: 'carton_pack_style_code' is invalid- could not be found in database")
		 return false
	end
end
 
def set_carton_pack_type

	carton_pack_type = CartonPackType.find_by_type_code(self.type_code)
	 if carton_pack_type != nil 
		 self.carton_pack_type = carton_pack_type
		 return true
	 else
		errors.add_to_base("value of: 'type_code'  is invalid- not found in database")
		 return false
	end
end
 
def set_basic_pack

	basic_pack = BasicPack.find_by_basic_pack_code(self.basic_pack_code)
	 if basic_pack != nil 
		 self.basic_pack = basic_pack
		 return true
	 else
		errors.add_to_base("value of: 'basic_pack_code'  is invalid- not found in database")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: carton_pack_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_type_codes

	type_codes = CartonPackType.find_by_sql('select distinct type_code from carton_pack_types').map{|g|[g.type_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: basic_pack_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_basic_pack_codes

	basic_pack_codes = BasicPack.find_by_sql('select distinct basic_pack_code from basic_packs').map{|g|[g.basic_pack_code]}
end






end
