class OrganizationsTargetMarket < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :organization
	belongs_to :target_market
 
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
		 is_valid = ModelHelper::Validations.validate_combos([{:short_description => self.short_description}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_organization
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:target_market_name => self.target_market_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_target_market
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = OrganizationsTargetMarket.find_by_short_description_and_target_market_name(self.short_description,self.target_market_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'short_description' and 'target_market_name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_organization

	organization = Organization.find_by_short_description(self.short_description)
	 if organization != nil 
		 self.organization = organization
		 return true
	 else
		errors.add_to_base("combination of: 'short_description'  is invalid- it must be unique")
		 return false
	end
end
 
def set_target_market

	target_market = TargetMarket.find_by_target_market_name(self.target_market_name)
	 if target_market != nil 
		 self.target_market = target_market
		 return true
	 else
		errors.add_to_base("combination of: 'target_market_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: organization_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_short_descriptions

	short_descriptions = Organization.find_by_sql('select distinct short_description from organizations').map{|g|[g.short_description]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: target_market_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_target_market_names

	target_market_names = TargetMarket.find_by_sql('select distinct target_market_name from target_markets').map{|g|[g.target_market_name]}
end






end
