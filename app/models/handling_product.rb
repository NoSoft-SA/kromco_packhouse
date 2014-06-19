class HandlingProduct < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :handling_product_type
#	validates_uniqueness_of :handling_product_code
	
#	============================
#	 Validations declarations:
#	============================
	#validates_presence_of :standard_size_count_code
	validates_presence_of :handling_product_code
	
#	=====================
#	 Complex validations:
#	=====================

  def before_validation
    puts "MY VALIDATION"
  
  end
  
 def before_save
 
 product = nil
 product = Product.find_by_product_code(self.handling_product_code)
  if ! product
   product = Product.new
   product.product_code = self.handling_product_code
   product.product_type_code = "HANDLING_PRODUCT"
   product.product_type = ProductType.find_by_product_type_code("HANDLING_PRODUCT")
   product.create
   
 else
  product.product_code = self.handling_product_code
  product.update
 end
 
end

def before_destroy
  Product.find_by_product_code(self.handling_product_code).destroy

end


def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:handling_product_type_code => self.handling_product_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_handling_product_type
	 end
	

end


#	===========================
#	 foreign key validations:
#	===========================
def set_handling_product_type

	handling_product_type = HandlingProductType.find_by_handling_product_type_code(self.handling_product_type_code)
	 if handling_product_type != nil 
		 self.handling_product_type = handling_product_type
		 return true
	 else
		errors.add_to_base("value of field: 'handling_product_type_code' is invalid- it must be unique")
		 return false
	end
end
 


end
