class TradeUnitSetup < ActiveRecord::Base

  belongs_to :handling_product
  belongs_to :product
  belongs_to :carton_setup
  
  belongs_to :carton_pack_product
  
  attr_reader :production_schedule_code,:org,:color_percentage,:grade_code,:std_count,
              :sequence_number,:order_number,:carton_fruit_mass_label
              
  attr_writer :production_schedule_code,:org,:color_percentage,:grade_code,:std_count,
              :sequence_number,:order_number,:carton_fruit_mass_label
              
  
  validates_presence_of :mark_code
  
  
  def before_update
   if !self.new_record?
    old_record = TradeUnitSetup.find(self.id)
    if old_record.carton_pack_product_code != self.carton_pack_product_code||old_record.mark_code != self.mark_code
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
 
 
   def get_calculated_mass
      #-------------------------------------------------------------------------------------------------------------
      #calculate carton mass as follows:
      #trade_unit nett mass default is: cpc nett mass, but if retail_unit has mass,
      #then trade unit nett mass = standard_count avg weight(i.e. fruit weight) * items per unit * units_per_carton
      #-------------------------------------------------------------------------------------------------------------
       carton_pack_product = self.carton_pack_product
	   carton_fruit_mass = carton_pack_product.nett_mass
	   fruit_mass = StandardCount.find_by_standard_count_value(self.carton_setup.standard_size_count_value).average_weight_gm.to_f
	
	  #fruit_mass = Float.round_float(2,fruit_mass/1000)
	  if fruit_mass && fruit_mass > 0
	    fruit_mass = fruit_mass/1000
      end
    
	  if fruit_mass && fruit_mass > 0  && self.carton_setup.retail_unit_setup.units_per_carton && self.carton_setup.retail_unit_setup.units_per_carton > 0 && self.carton_setup.retail_unit_setup.items_per_unit && self.carton_setup.retail_unit_setup.items_per_unit > 0 
	  
	    carton_fruit_mass = fruit_mass * self.carton_setup.retail_unit_setup.units_per_carton * self.carton_setup.retail_unit_setup.items_per_unit
	  
	  end
	
	  carton_fruit_mass = Float.round_float(2,carton_fruit_mass) if carton_fruit_mass && carton_fruit_mass > 0
      return carton_fruit_mass
   
   end
 
 
   def production_schedule_code
    puts "psc attrib called"
    if @production_schedule_code == nil
      @production_schedule_code = self.carton_setup.production_schedule_code
    end
    
    return @production_schedule_code
  end
    
  def validate

    self.standard_label_code = "CTN1"

     puts "IN VALIDATE"
    is_valid = true	
	if is_valid
		 ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code}],self,true) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if self.pack_material_product_code
		 is_valid = set_pack_material_product
	 else
	   self.product = nil
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:carton_pack_product_code => self.carton_pack_product_code}],self) 
	 end
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_carton_pack_product
	 end
	 
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:standard_label_code => self.standard_label_code}],self) 
	 end
	
	ModelHelper::Validations.validate_combos([{:handling_product_code => self.handling_product_code}],self,true) 
	
	ModelHelper::Validations.validate_combos([{:old_pack_code => self.old_pack_code}],self,true) 
	 
	#now check whether fk combos combine to form valid foreign keys
	 if self.handling_product_code
		 is_valid = set_handling_product
	 else
	   self.handling_message = nil
	   self.handling_product = nil
	 end
	 
	 #--------------------------
	 #Nett mass not used anymore
	 #--------------------------
	 #calculated nett mass- use only if user did not override calculation
#	 if !self.carton_fruit_mass && is_valid == true
#	   self.carton_fruit_mass = get_calculated_mass
#	   if !self.carton_fruit_mass ||self.carton_fruit_mass == 0
#	     errors.add("carton_fruit_mass","must have a value. You can manually enter a value OR <BR> the system can calculate a value, BUT <br> The system needs the field 'average weight gm' of the current standard count(then items-per-unit and 'units_per_carton' must have values at retail unit setup)<BR> OR the CPC must have a mass(specified with CPC CRUD tool)")
#	   end
#	 end
	   
end

#	===========================
#	 foreign key validations:
#	===========================

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
