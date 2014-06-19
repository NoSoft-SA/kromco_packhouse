class RunPalletizingCriterium < ActiveRecord::Base


 belongs_to :production_run
 belongs_to :carton_setup
 
 def validate
   
	is_valid = ModelHelper::Validations.validate_combos([{:fg_product_code => self.fg_product_code},{:carton_setup_code => self.carton_setup_code}],self) 
   
	#now check whether fk combos combine to form valid foreign keys
   
 
 end
 
 
end
