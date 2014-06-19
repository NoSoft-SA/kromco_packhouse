class DrenchLine < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :drench_line_type
	has_many :drench_stations
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :drench_line_code
  validates_presence_of :drench_line_type_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:drench_line_type_code => self.drench_line_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_drench_line_type
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_drench_line_type

	drench_line_type = DrenchLineType.find_by_drench_line_type_code(self.drench_line_type_code)
	 if drench_line_type != nil 
		 self.drench_line_type = drench_line_type
		 return true
	 else
		errors.add_to_base("value of field: 'drench_line_type_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
