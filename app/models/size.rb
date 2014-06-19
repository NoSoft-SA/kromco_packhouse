class Size < ActiveRecord::Base
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :commodity
 
#	============================
#	 Validations declarations:
#	============================
	
	validates_presence_of :size_code
	
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_commodity
	 end
	 
	if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:equivalent_count_from => self.equivalent_count_from}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_equivalent_count_from
	 end
	 
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:equivalent_count_to => self.equivalent_count_to}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_equivalent_count_to
	 end
	 
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Size.find_by_commodity_code_and_size_code(self.commodity_code,self.size_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_code' and 'size_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_commodity

	commodity = Commodity.find_by_commodity_code(self.commodity_code)
	 if commodity != nil 
		 self.commodity = commodity
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_code'  is invalid- it must be unique")
		 return false
	end
end

def set_equivalent_count_from
   
	count = StandardCount.find_by_commodity_code_and_standard_count_value(self.commodity_code,self.equivalent_count_from)
	
	 if count != nil 
		 self.equivalent_count_from_id = count.id
		 return true
	 else
		errors.add_to_base("equivalent_count_from could not be found for commodity and count value")
		 return false
	end
end

def set_equivalent_count_to

	count_id = StandardCount.find_by_commodity_code_and_standard_count_value(self.commodity_code,self.equivalent_count_to).id
	 if count_id != nil 
		 self.equivalent_count_to_id = count_id
		 return true
	 else
		errors.add_to_base("equivalent_count_to could not be found for commodity and count value")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: commodity_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes

	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
end



end
