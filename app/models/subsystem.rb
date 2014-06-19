class Subsystem < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :system
	
 
#	============================
#	 Validations declarations:
#	============================
#	===========================
#	 lookup methods:
#	===========================

 def validate
    is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:system_name => self.system_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_system
	 end
 
 end
 
 def set_system

	system = System.find_by_system_name(self.system_name)
	 if system != nil 
		 self.system = system
		 return true
	 else
		errors.add_to_base("'system'  is invalid")
		 return false
	end
end
 

end
