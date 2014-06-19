class RouteStep < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :route_step_type
 
#	============================
#	 Validations declarations:
#	============================
  validates_presence_of :route_step_code
#	=====================
#	 Complex validations:
#	=====================
#def validate
##	first check whether combo fields have been selected
#	 is_valid = true
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
##		 is_valid = set_route_step_type
#	 end
#end

#	===========================
#	 foreign key validations:
#	===========================
def set_route_step_type

	route_step_type = RouteStepType.find_by_route_step_type_code(self.route_step_type_code)
	 if route_step_type != nil 
		 self.route_step_type = route_step_type
		 return true
	 else
		errors.add_to_base("value of field: 'route_step_type_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
