class ProductionRunPackMaterial < ActiveRecord::Base
  
  belongs_to :production_run 
  belongs_to :carton_setup
  belongs_to :fg_product
  
  attr_accessor :production_schedule_name,:commodity_code,:marketing_variety_code,
               :line_code,:production_run_number
  
  
  
  def validate
    is_valid = true
     if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:fg_product_code => self.fg_product_code},{:carton_setup_code => self.carton_setup_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	if is_valid
		 is_valid = set_carton_setup
	end
  
  end
  
  
  def set_carton_setup
   #self.carton_setup_code is the id of the selected carton setup(set directly from the UI dropdown)) 
   self.carton_setup = CartonSetup.find(self.carton_setup_code.to_i)
   self.carton_setup_code = self.carton_setup.carton_setup_code
  
  end
  
  
  def before_save
   
    self.fg_product = FgProduct.find_by_fg_product_code(self.fg_product_code)
  
  end
               
               
end

