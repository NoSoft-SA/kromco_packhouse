class Product < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Product.find_by_product_subtype_code_and_tag1_and_tag2_and_tag3_and_product_code(self.product_subtype_code,self.tag1,self.tag2,self.tag3,self.product_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'product_subtype_code' and 'tag1' and 'tag2' and 'tag3' and 'product_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
