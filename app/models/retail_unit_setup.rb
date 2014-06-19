class RetailUnitSetup < ActiveRecord::Base

  belongs_to :handling_product
  belongs_to :product
  belongs_to :carton_setup
  
  belongs_to :unit_pack_product
  
  attr_reader :production_schedule_code,:org,:color_percentage,:grade_code,
              :sequence_number,:order_number,:std_count
              
  attr_writer :production_schedule_code,:org,:color_percentage,:grade_code,
              :sequence_number,:order_number,:std_count
              
 
  
  #-----------------------------------------------------------------
  #If UPC changed, then fg_product_code must be re-calculated
  # and carton_template and carton_label_setup must be 
  # deleted and carton_setup's field 'labels_and_templates_created'
  # must be set to nil
  #-----------------------------------------------------------------
   def production_schedule_code
    puts "psc attrib called"
    if @production_schedule_code == nil
      @production_schedule_code = self.carton_setup.production_schedule_code
    end
    
    return @production_schedule_code
  end
  
  def before_save
   
   if !self.new_record?
    old_record = RetailUnitSetup.find(self.id)
    if old_record.unit_pack_product_code != self.unit_pack_product_code||old_record.mark_code != self.mark_code
     @recalc_fg = true
    end
  end
  end
  
  def after_save
    self.carton_setup.update_time
    if @recalc_fg && self.carton_setup.fg_setup
      self.carton_setup.fg_setup.production_schedule_code = self.carton_setup.production_schedule_code
      self.carton_setup.fg_setup.save
    end
  end
  
  def after_create
   self.carton_setup.update_time
  end
  
  
  def validate 
    
    is_valid = true	
	#if is_valid
		 ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code}],self,true) 
	#end
	
	#now check whether fk combos combine to form valid foreign keys
	if self.pack_material_product_code
		 is_valid = set_pack_material_product
	else
	  self.product = nil
	end
	if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:unit_pack_product_code => self.unit_pack_product_code}],self) 
	end
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_unit_pack_product
	 end
	 
		 ModelHelper::Validations.validate_combos([{:handling_product_code => self.handling_product_code}],self,true) 
	 
	#now check whether fk combos combine to form valid foreign keys
	 if self.handling_product_code
		 is_valid = set_handling_product
	 else
	   self.handling_message = nil
	   self.handling_product = nil
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
