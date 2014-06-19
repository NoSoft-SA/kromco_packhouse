class ProcessAlertTrigger < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = ProcessAlertTrigger.find_by_trigger_name(self.trigger_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'trigger_name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
