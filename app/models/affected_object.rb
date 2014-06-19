class AffectedObject < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :affected_object_type
	belongs_to :subsystem

 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true


	 puts "VALID: " + is_valid.to_s
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:system_name => self.system_name},{:subsystem_name => self.subsystem_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_subsystem
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:affected_object_type_name => self.affected_object_type_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_affected_object_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = AffectedObject.find_by_system_name_and_subsystem_name_and_affected_object_type_name_and_affected_object_name(self.system_name,self.subsystem_name,self.affected_object_type_name,self.affected_object_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'system_name' and 'subsystem_name' and 'affected_object_type_name' and 'affected_object_name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_affected_object_type

	affected_object_type = AffectedObjectType.find_by_affected_object_type_name(self.affected_object_type_name)
	 if affected_object_type != nil 
		 self.affected_object_type = affected_object_type
		 return true
	 else
		errors.add_to_base("value of field: 'affected_object_type_name' is invalid- it must be unique")
		 return false
	end
end
 
def set_subsystem

	subsystem = Subsystem.find_by_system_name_and_subsystem_name(self.system_name,self.subsystem_name)
	 if subsystem != nil 
		 self.subsystem = subsystem
		 return true
	 else
		errors.add_to_base("combination of: 'system_name' and 'subsystem_name'  is invalid- it must be unique")
		 return false
	end
end
 

#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: subsystem_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_system_names

	system_names = Subsystem.find_by_sql('select distinct system_name from subsystems').map{|g|[g.system_name]}
end



def self.get_all_subsystem_names

	subsystem_names = Subsystem.find_by_sql('select distinct subsystem_name from subsystems').map{|g|[g.subsystem_name]}
end



def self.subsystem_names_for_system_name(system_name)

	subsystem_names = Subsystem.find_by_sql("Select distinct subsystem_name from subsystems where system_name = '#{system_name}'").map{|g|[g.subsystem_name]}

	subsystem_names.unshift("<empty>")
 end








end
