class FgProduct < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
   belongs_to :product
   belongs_to :item_pack_product
   belongs_to :unit_pack_product
   belongs_to :carton_pack_product
#	============================
#	 Validations declarations:
#	============================
	#validates_presence_of :fg_product_code
	
	
	def FgProduct.fg_codes_for_schedule(schedule_code)
	
	 query = "SELECT distinct
              public.fg_setups.fg_product_code
              FROM
              public.fg_setups
              INNER JOIN public.carton_setups ON (public.fg_setups.carton_setup_id = public.carton_setups.id)
              WHERE
             (public.carton_setups.production_schedule_code = '#{schedule_code}') ORDER BY fg_product_code"
	
	 return FgProduct.find_by_sql(query).map{|fg|fg.fg_product_code}
	
	end
	
	
	def before_destroy
	
	 self.product.destroy
	end
	
	def before_create
 
      product = nil
      product = Product.find_by_product_code(self.fg_product_code)
      if ! product
        product = Product.new
        product.product_code = self.fg_product_code
        product.product_type_code = "FINISHED_GOOD"
        product.product_type = ProductType.find_by_product_type_code("FINISHED_GOOD")
        product.create
      end
 
      self.product = product
 
      end
	
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
    
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:unit_pack_product_code => self.unit_pack_product_code}],self) 
	 end
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_unit_pack_product
	 end
	 
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:item_pack_product_code => self.item_pack_product_code}],self) 
	end
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_item_pack_product
	 end
	 
	  if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:carton_pack_product_code => self.carton_pack_product_code}],self) 
	 end
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_carton_pack_product
	 end
	  
	#validates uniqueness for this record
	if is_valid
	 puts "fg prod create"
	 self.fg_product_code = self.item_pack_product.get_ipc_code_for_fg + "_" + self.unit_pack_product_code + "_" + self.carton_pack_product_code
	end
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
	 
	 puts "fg errs " + self.errors.full_messages.to_s
end

def validate_uniqueness
#	 exists = FgProduct.find_by_item_pack_product_code_and_unit_pack_product_code_and_carton_pack_product_code(self.item_pack_product_code,self.unit_pack_product_code,self.carton_pack_product_code)
#	 
#	 if exists != nil 
#		errors.add_to_base("There already exists a record with the combined values of fields: 'item_pack_product_code' and 'unit_pack_product_code' and 'carton_pack_product_code' ")
#	end
end

#	===========================
#	 foreign key validations:
#	===========================
 def set_unit_pack_product

	unit_pack = UnitPackProduct.find_by_unit_pack_product_code(self.unit_pack_product_code)
	 if unit_pack != nil 
		 self.unit_pack_product = unit_pack
		 return true
	 else
		errors.add_to_base("'unit_pack product code' is invalid")
		 return false
	end
end

def set_item_pack_product

	item_pack = ItemPackProduct.find_by_item_pack_product_code(self.item_pack_product_code)
	 if item_pack != nil 
		 self.item_pack_product = item_pack
		 return true
	 else
		errors.add_to_base("'item_pack product code' is invalid")
		 return false
	end
end

def set_carton_pack_product

	carton_pack = CartonPackProduct.find_by_carton_pack_product_code(self.carton_pack_product_code)
	 if carton_pack != nil 
		 self.carton_pack_product = carton_pack
		 return true
	 else
		errors.add_to_base("'carton_pack product code' is invalid")
		 return false
	end
end


end
