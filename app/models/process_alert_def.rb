class ProcessAlertDef < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :status
 
#	============================
#	 Validations declarations:
#	============================
#	validates_numericality_of :process_interval
#	validates_numericality_of :alert_time_frame
#	=====================
#	 Complex validations:
#	=====================
  
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:status_type_code => self.status_type_code}],self)
#	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_status
	 end
	#validates uniqueness for this record
#	 if self.new_record? && is_valid
#		 validate_uniqueness
#	 end
end

#def validate_uniqueness
#	 exists = ProcessAlertDef.find_by_trigger_name(self.trigger_name)
#	 if exists != nil
#		errors.add_to_base("There already exists a record with the combined values of fields: 'trigger_name' ")
#	end
#end
#	===========================
#	 foreign key validations:
#	===========================
def set_status
#email                     = RailsErrorMail.create_set_error_details(RailsError.new)
#    email.set_content_type("text/html")
#    RailsErrorMail.deliver(email)
	status = Status.find(self.status_id)
	 if status != nil 
		 self.status = status
		 return true
	 else
		errors.add_to_base("combination of: 'status_type_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: status_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_status_type_codes

	status_type_codes = Status.find_by_sql('select distinct status_type_code from statuses').map{|g|[g.status_type_code]}
end






end
