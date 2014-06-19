class MarksOrganization < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :mark
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
		 is_valid = ModelHelper::Validations.validate_combos([{:mark_code => self.mark_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_mark
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:short_description => self.short_description}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_organization
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = MarksOrganization.find_by_short_description_and_mark_code(self.short_description,self.mark_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'short_description' and 'mark_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_mark

	mark = Mark.find_by_mark_code(self.mark_code)
	 if mark != nil 
		 self.mark = mark
		 return true
	 else
		errors.add_to_base("combination of: 'mark_code'  is invalid- it must be unique")
		 return false
	end
end
 
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
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: mark_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_mark_codes

	mark_codes = Mark.find_by_sql('select distinct mark_code from marks').map{|g|[g.mark_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: organization_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_short_descriptions

	short_descriptions = Organization.find_by_sql('select distinct short_description from organizations').map{|g|[g.short_description]}
end






end
