class DowntimeDivision < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :downtime_category
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :downtime_category_code
	validates_presence_of :downtime_division_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:downtime_category_code => self.downtime_category_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_downtime_category
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = DowntimeDivision.find_by_downtime_category_code_and_downtime_division_code(self.downtime_category_code,self.downtime_division_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'downtime_category_code' and 'downtime_division_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_downtime_category

	downtime_category = DowntimeCategory.find_by_downtime_category_code(self.downtime_category_code)
	 if downtime_category != nil 
		 self.downtime_category = downtime_category
		 return true
	 else
		errors.add_to_base("combination of: 'downtime_category_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: downtime_category_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_downtime_category_codes

	downtime_category_codes = DowntimeCategory.find_by_sql('select distinct downtime_category_code from downtime_categories').map{|g|[g.downtime_category_code]}
end






end
