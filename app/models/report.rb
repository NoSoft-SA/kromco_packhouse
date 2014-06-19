class Report < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :report_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :version_number
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:report_type_code => self.report_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_report_type
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_report_type

	report_type = ReportType.find_by_report_type_code(self.report_type_code)
	 if report_type != nil 
		 self.report_type = report_type
		 return true
	 else
		errors.add_to_base("value of field: 'report_type_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
