class Rule < ActiveRecord::Base 
	attr_accessor :rule_type_code
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :rule_type
 
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
		 is_valid = ModelHelper::Validations.validate_combos([{:rule_type_code => self.rule_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_rule_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Rule.find_by_rule_code(self.rule_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'rule_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_rule_type

	rule_type = RuleType.find_by_rule_type_code(self.rule_type_code)
	 if rule_type != nil 
		 self.rule_type = rule_type
		 return true
	 else
		errors.add_to_base("value of field: 'rule_type_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
