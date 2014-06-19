class Commodity < ActiveRecord::Base
 
 belongs_to :commodity_group
 validates_presence_of :commodity_code
 
 
 def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_commodity_group
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Commodity.find_by_commodity_code(self.commodity_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_commodity_group

	commodity_group = CommodityGroup.find_by_commodity_group_code(self.commodity_group_code)
	 if commodity_group != nil 
		 self.commodity_group = commodity_group
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_group_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: commodity_group_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_group_codes

	commodity_group_codes = CommodityGroup.find_by_sql('select distinct commodity_group_code from commodity_groups').map{|g|[g.commodity_group_code]}
end


 

end
