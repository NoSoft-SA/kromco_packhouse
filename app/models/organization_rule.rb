class OrganizationRule < ActiveRecord::Base 
	attr_accessor :short_description, :rule_code, :rule_type
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :rule
	belongs_to :organization
 
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
		 is_valid = ModelHelper::Validations.validate_combos([{:rule_code => self.rule_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_rule
	 end
end

#	===========================
#	 foreign key validations:
#	===========================


  def self.get_rules(org_code,rule_type_code,return_as_records = nil)

    query = "select rules.rule_code,rules.rule_description as description from rules inner join organization_rules on(organization_rules.rule_id = rules.id)
                      inner join rule_types on(rules.rule_type_id = rule_types.id)
                      inner join organizations on(organization_rules.organization_id = organizations.id)
                      where rule_types.rule_type_code = '#{rule_type_code}' and organizations.short_description = '#{org_code}'"

    if ! return_as_records
      return self.connection.select_all(query).map{|r|r['rule_code']}
    else
      return self.connection.select_all(query)
    end

  end

def set_rule

	rule = Rule.find_by_rule_code(self.rule_code)
	 if rule != nil 
		 self.rule = rule
		 return true
	 else
		errors.add_to_base("combination of: 'rule_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_organization

	organization = Organization.find_by_short_description(self.short_description)
	 if organization != nil 
		 self.organization = organization
		 return true
	 else
		errors.add_to_base("combination of: 'short_description' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: rule_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_rule_codes

	rule_codes = Rule.find_by_sql('select distinct rule_code from rules').map{|g|[g.rule_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: organization_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_short_descriptions

	short_descriptions = Organization.find_by_sql('select distinct short_description from organizations').map{|g|[g.short_description]}
end


end
