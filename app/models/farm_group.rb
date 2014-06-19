class FarmGroup < ActiveRecord::Base
 validates_presence_of :farm_group_code
 validates_uniqueness_of :farm_group_code
 
 has_many :farms
 
 def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = FarmGroup.find_by_farm_group_code(self.farm_group_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'farm_group_code' ")
	end
end
 
end
