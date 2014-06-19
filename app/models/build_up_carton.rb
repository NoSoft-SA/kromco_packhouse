class BuildUpCarton < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :build_up
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
#def validate
##	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:buildup_timestamp => self.buildup_timestamp}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_build_up
#	 end
#end

#	===========================
#	 foreign key validations:
#	===========================
#def set_build_up
#
#	build_up = BuildUp.find_by_buildup_timestamp(self.buildup_timestamp)
#	 if build_up != nil
#		 self.build_up = build_up
#		 return true
#	 else
#		errors.add_to_base("value of field: 'buildup_timestamp' is invalid- it must be unique")
#		 return false
#	end
#end
 
#	===========================
#	 lookup methods:
#	===========================



end
