class Person < ActiveRecord::Base


 #	===========================
# 	Association declarations:
#	===========================
 
	belongs_to :party
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :first_name
	validates_presence_of :last_name
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 
	#validates uniqueness for this record
	 if self.new_record?
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Person.find_by_first_name_and_last_name(self.first_name,self.last_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'first_name' and 'last_name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_party

	party = Party.find_by_party_name_and_party_type_id(self.party_name,self.party_type_id)
	 if party != nil 
		 self.party = party
		 return true
	 else
		errors.add_to_base("combination of: 'party_name' and 'party_type_id'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: party_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_party_names

	party_names = Party.find_by_sql('select distinct party_name from parties').map{|g|[g.party_name]}
end



def self.get_all_party_type_ids

	party_type_ids = Party.find_by_sql('select distinct party_type_id from parties').map{|g|[g.party_type_id]}
end



def self.party_type_ids_for_party_name(party_name)

	party_type_ids = Party.find_by_sql("Select distinct party_type_id from parties where party_name = '#{party_name}'").map{|g|[g.party_type_id]}

	party_type_ids.unshift("<empty>")
 end
 
 
	def self.allEmployees
		
		query = "SELECT people.last_name,people.first_name,people.id FROM people
  		INNER JOIN parties ON (people.party_id = parties.id)
  		INNER JOIN parties_roles ON (parties.id = parties_roles.party_id)
		WHERE (parties_roles.role_name = 'EMPLOYEE')
		ORDER BY people.last_name ASC"
	
		allEmployees = self.find_by_sql(query).map {|u| [u.last_name + ', ' + u.first_name, u.id]}
		
	end
	
	
	def self.allEmployees_as_text
		
		query = "SELECT people.last_name,people.first_name,people.id FROM people
  		INNER JOIN parties ON (people.party_id = parties.id)
  		INNER JOIN parties_roles ON (parties.id = parties_roles.party_id)
		WHERE (parties_roles.role_name = 'EMPLOYEE')
		ORDER BY people.last_name ASC"
	
		allEmployees = self.find_by_sql(query).map {|u| [u.last_name + ', ' + u.first_name]}
		
	end
	
	
	
	
    
    def self.all_it_staff
		
		query = "SELECT people.last_name,people.first_name,people.id FROM people
  		INNER JOIN parties ON (people.party_id = parties.id)
  		INNER JOIN parties_roles ON (parties.id = parties_roles.party_id)
		WHERE (UPPER(parties_roles.role_name) = 'IT')
		ORDER BY people.last_name ASC"
	
		allEmployees = self.find_by_sql(query).map {|u| [u.first_name.to_s + " " +  u.last_name.to_s]}
		
	end
	
 def destroy_employee
  
  #destroy only the role
  role = self.party.roles.find(2)
  self.party.roles.delete(role)
  self.destroy
  

 end
 
 
 def before_save
    party = nil
    if self.new_record?
      party = Party.new
    else
      party = self.party
    end
    party.party_type_id = 1
    party.party_type_name = "PERSON"
    party.party_name = self.first_name + "_" + self.last_name
    party.save
    self.party = party
 
 end
 
 def after_destroy
  self.party.destroy
 
 end
 

end
