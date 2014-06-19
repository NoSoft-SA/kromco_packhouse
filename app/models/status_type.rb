class StatusType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
has_many :statuses
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :status_type_code

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
	 exists = StatusType.find_by_status_type_code(self.status_type_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'status_type_code' ")
	end
end

def before_destroy
    Status.destroy_all(["status_type_code = ?",self.status_type_code])
end






end
