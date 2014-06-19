class PresortLog < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :rails_error
 
#	============================
#	 Validations declarations:
#	============================
#	validates_presence_of :input_params
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_rails_error
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_rails_error

  if(self.rails_error_id)
    rails_error = RailsError.find(self.rails_error_id)
     if rails_error != nil
       self.rails_error = rails_error
       return true
     else
      errors.add_to_base("value of field: 'rails_error' is invalid- it must be unique")
       return false
     end
  end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
