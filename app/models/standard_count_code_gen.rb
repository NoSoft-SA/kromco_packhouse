class StandardCount < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :commodity
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :standard_count_value
	validates_presence_of :commodity_code
	validates_numericality_of :marketing_size_range_mm
	validates_numericality_of :standard_count_value
	validates_numericality_of :marketing_weight_range
	validates_numericality_of :average_size_mm
	validates_numericality_of :minimum_size_mm
	validates_numericality_of :maximum_size_mm
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
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = StandardCount.find_by_standard_count_value(self.standard_count_value)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'standard_count_value' ")
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
