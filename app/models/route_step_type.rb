class RouteStepType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
  has_many :route_steps, :dependent => :destroy
 
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
end

#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
