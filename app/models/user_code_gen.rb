class User < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :person
	belongs_to :department
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :department_name
	validates_presence_of :first_name
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:department_name => self.department_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_department
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:first_name => self.first_name},{:last_name => self.last_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_person
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = User.find_by_user_name(self.user_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'user_name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_person

	person = Person.find_by_first_name_and_last_name(self.first_name,self.last_name)
	 if person != nil 
		 self.person = person
		 return true
	 else
		errors.add_to_base("combination of: 'first_name' and 'last_name'  is invalid- it must be unique")
		 return false
	end
end
 
def set_department

	department = Department.find_by_department_name(self.department_name)
	 if department != nil 
		 self.department = department
		 return true
	 else
		errors.add_to_base("combination of: 'department_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: person_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_first_names

	first_names = Person.find_by_sql('select distinct first_name from people').map{|g|[g.first_name]}
end



def self.get_all_last_names

	last_names = Person.find_by_sql('select distinct last_name from people').map{|g|[g.last_name]}
end



def self.last_names_for_first_name(first_name)

	last_names = Person.find_by_sql("Select distinct last_name from people where first_name = '#{first_name}'").map{|g|[g.last_name]}

 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: department_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_department_names

	department_names = Department.find_by_sql('select distinct department_name from departments').map{|g|[g.department_name]}
end






end
