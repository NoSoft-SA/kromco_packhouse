class ProbeStatusHistory < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :status
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:status_code => self.status_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_status
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_status

	status = Status.find_by_status_code(self.status_code)
	 if status != nil 
		 self.status = status
		 return true
	 else
		errors.add_to_base("value of field: 'status_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
