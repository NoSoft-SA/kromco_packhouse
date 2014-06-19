class StoredPdtProcess < ActiveRecord::Base 
	
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
	 exists = StoredPdtProcess.find_by_user_process_name(self.user_process_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'user_process_name' ")
	end
end

def cancel_clear_combo_prompts
  true
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
