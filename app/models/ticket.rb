class Ticket < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :project
 
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
		 is_valid = ModelHelper::Validations.validate_combos([{:project_name => self.project_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_project
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Ticket.find_by_project_name_and_ticket_name_and_status(self.project_name,self.ticket_name,self.status)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'project_name' and 'ticket_name' and 'status' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_project

	project = Project.find_by_project_name(self.project_name)
	 if project != nil 
		 self.project = project
		 return true
	 else
		errors.add_to_base("combination of: 'project_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: project_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_project_names

	project_names = Project.find_by_sql('select distinct project_name from projects').map{|g|[g.project_name]}
end






end
