class CommodityGroup < ActiveRecord::Base

#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :commodity_group_code
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
	 exists = CommodityGroup.find_by_commodity_group_code(self.commodity_group_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_group_code' ")
	end
end

end
