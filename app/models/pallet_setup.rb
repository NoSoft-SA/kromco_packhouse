class PalletSetup < ActiveRecord::Base

  belongs_to :handling_product
  belongs_to :product
  belongs_to :carton_setup
  
  belongs_to :pallet_format_product
  
  attr_reader :production_schedule_code,:org,:color_percentage,:grade_code,
              :sequence_number,:order_number,:item_pack_product_code,:std_count,:palletizing
              
  attr_writer :production_schedule_code,:org,:color_percentage,:grade_code,
              :sequence_number,:order_number,:item_pack_product_code,:std_count,:palletizing
              
  
  def after_find
   cpp = " "
   cpp = self.no_of_cartons.to_s if self.no_of_cartons
   pfp = ""
   pfp = self.pallet_format_product_code if self.pallet_format_product_code
   
   self.palletizing = pfp + cpp
  
  end
  
  def after_save
    self.carton_setup.update_time
  end
  
  def after_create
   self.carton_setup.update_time
  end
  
  #validates_numericality_of :no_of_cartons
  
  def production_schedule_code
    puts "psc attrib called"
    if @production_schedule_code == nil
      @production_schedule_code = self.carton_setup.production_schedule_code
    end
    
    return @production_schedule_code
  end
  
  
  def before_save
    self.grade_code = self.carton_setup.grade_code
  
  end
  
  
  
  def validate 
     
    is_valid = true
    self.label_code = "PAL1"
	
	if !self.no_of_cartons ||self.no_of_cartons == 0
	  errors.add :no_of_cartons, " cannot be blank. Populate this field by selecting a value from 'pallet_format_product <br> If selection from that field does not populate the 'no_of_cartons' dropdown, then you <br> need to create a new 'cpp' record under 'products/cpp'"
	end
	ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code}],self,true) 
	
	#now check whether fk combos combine to form valid foreign keys
	 if self.pack_material_product_code
		 is_valid = set_pack_material_product
	 else
	  self.product = nil
	 end
	 
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:pallet_format_product_code => self.pallet_format_product_code}],self) 
	 end
	 
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:inspection_type_code => self.inspection_type_code}],self) 
	 end
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pallet_format_product
	 end
	 
	 ModelHelper::Validations.validate_combos([{:handling_product_code => self.handling_product_code}],self,true) 
	
	#now check whether fk combos combine to form valid foreign keys
	 if self.handling_product_code
		 is_valid = set_handling_product
	 else
	    self.handling_message = nil
	    self.handling_product = nil
	 end
	 
	 if is_valid
	   set_pallet_format_product
	 end
	 
	
end

#	===========================
#	 foreign key validations:
#	===========================
def set_pack_material_product

	pack_material_product = Product.find_by_product_code(self.pack_material_product_code)
	 if pack_material_product != nil 
		 self.product = pack_material_product
		 return true
	 else
		errors.add_to_base("'pack_material_product_code' is invalid: not found in database")
		 return false
	end
end
 
def set_pallet_format_product

	pallet_format = PalletFormatProduct.find_by_pallet_format_product_code(self.pallet_format_product_code)
	 if pallet_format != nil 
		 self.pallet_format_product = pallet_format
		 return true
	 else
		errors.add_to_base("'pallet format product code' is invalid")
		 return false
	end
end
 
def set_handling_product
    
	handling_product = HandlingProduct.find_by_handling_product_code(self.handling_product_code)
	 if handling_product != nil 
		 self.handling_product = handling_product
		 self.handling_message = handling_product.handling_message
		 return true
	 else
		errors.add_to_base("'handling_product_code'  is invalid")
		 return false
	end
end


end
