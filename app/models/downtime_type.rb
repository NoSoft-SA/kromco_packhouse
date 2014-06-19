class DowntimeType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :downtime_division
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :downtime_type_code
	validates_presence_of :downtime_category_code
	validates_presence_of :downtime_division_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:downtime_category_code => self.downtime_category_code},{:downtime_division_code => self.downtime_division_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_downtime_division
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = DowntimeType.find_by_downtime_category_code_and_downtime_division_code_and_downtime_type_code(self.downtime_category_code,self.downtime_division_code,self.downtime_type_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'downtime_category_code' and 'downtime_division_code' and 'downtime_type_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_downtime_division

	downtime_division = DowntimeDivision.find_by_downtime_category_code_and_downtime_division_code(self.downtime_category_code,self.downtime_division_code)
	 if downtime_division != nil 
		 self.downtime_division = downtime_division
		 return true
	 else
		errors.add_to_base("combination of: 'downtime_category_code' and 'downtime_division_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: downtime_division_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_downtime_category_codes

	downtime_category_codes = DowntimeDivision.find_by_sql('select distinct downtime_category_code from downtime_divisions').map{|g|[g.downtime_category_code]}
end



def self.get_all_downtime_division_codes

	downtime_division_codes = DowntimeDivision.find_by_sql('select distinct downtime_division_code from downtime_divisions').map{|g|[g.downtime_division_code]}
end



def self.downtime_division_codes_for_downtime_category_code(downtime_category_code)

	downtime_division_codes = DowntimeDivision.find_by_sql("Select distinct downtime_division_code from downtime_divisions where downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_division_code]}

	downtime_division_codes.unshift("<empty>")
 end






end
