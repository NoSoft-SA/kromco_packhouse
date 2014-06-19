class ConcentrateProduct < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :product
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :min_quantity
	validates_numericality_of :max_quantity
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:product_code => self.product_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_product
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_product

	product = Product.find_by_product_code(self.concentrate_code)
	 if product != nil 
		 self.product = product
		 return true
	 else
		errors.add_to_base("could not find a product with this code")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: product_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_product_codes

	product_codes = Product.find_by_sql('select distinct product_code from products').map{|g|[g.product_code]}
end






end
