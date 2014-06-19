class RmtVariety < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :variety_group
	belongs_to :commodity
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :rmt_variety_code
	#validates_numericality_of :quality_test_code
	#validates_numericality_of :sample_percentage
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:variety_group_code => self.variety_group_code},{:commodity_code => self.commodity_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_variety_group
	 end
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
	 exists = RmtVariety.find_by_commodity_code_and_rmt_variety_code(self.commodity_code,self.rmt_variety_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_code' and 'rmt_variety_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_variety_group

	variety_group = VarietyGroup.find_by_variety_group_code_and_commodity_code(self.variety_group_code,self.commodity_code)
	 if variety_group != nil 
		 self.variety_group = variety_group
		 return true
	 else
		errors.add_to_base("combination of: 'variety_group_code' and 'commodity_code'  does not exist in variety_groups")
		 return false
	end
end
 
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
#	Lookup methods for the foreign composite key of id field: variety_group_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_variety_group_codes

	variety_group_codes = VarietyGroup.find_by_sql('select distinct variety_group_code from variety_groups').map{|g|[g.variety_group_code]}
end



def self.get_all_commodity_codes

	commodity_codes = VarietyGroup.find_by_sql('select distinct commodity_code from variety_groups').map{|g|[g.commodity_code]}
end


def self.get_all_commodity_group_codes

	commodity_group_codes = Commodity.find_by_sql('select distinct commodity_group_code from commodities').map{|g|[g.commodity_group_code]}
end

def self.commodity_codes_for_variety_group_code(variety_group_code)

	commodity_codes = VarietyGroup.find_by_sql("Select distinct commodity_code from variety_groups where variety_group_code = '#{variety_group_code}'").map{|g|[g.commodity_code]}

	commodity_codes.unshift("<empty>")
 end

def self.commodity_codes_for_commodity_group_code(commodity_group_code)

	commodity_codes = Commodity.find_by_sql("Select distinct commodity_code from commodities where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}

	commodity_codes.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: commodity_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes

	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
end






end
