class ForceLocationRule < ActiveRecord::Base 

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
   	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:force_to => self.force_to},{:force_from => self.force_from}],self)
	end

  if is_valid
    is_valid = test_difference
  end
#  	 if self.new_record? && is_valid
#
#
#		 validate_uniqueness
#	 end
end
def test_difference

   if (self.force_from != self.force_to )
     return true
   else
     errors.add_to_base("force_from and force_to cannot be the same ")
   end

end
def validate_uniqueness

	 exists = ForceLocationRule.find_by_force_from_and_force_to(self.force_from,self.force_to)

	 if ((exists != nil) )
		errors.add_to_base("There already exists a record with the combination of 'force_from' and 'force_to' ")
	end
end


def ForceLocationRule.get_force_to_values(force_from_value)
  force_from_occurences = ForceLocationRule.find_by_force_from(force_from_value)
  if(force_from_occurences != nil)
    ForceLocationRule.find_by_sql("select distinct force_to from force_location_rules where force_from = '"+force_from_value+"'")
  else
    return force_from_occurences
  end
end

end
