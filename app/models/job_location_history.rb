class JobLocationHistory < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :location
	belongs_to :precool_job
	belongs_to :facility
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :location_code
	validates_presence_of :units_in_location
	validates_numericality_of :units_in_location
	validates_numericality_of :location_maximum_units
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:location_id => self.location_id}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_precool_job
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:facility_type_code => self.facility_type_code},{:facility_code => self.facility_code},{:id => self.id}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_facility
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:location_code => self.location_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_location
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_location

	location = Location.find_by_location_code(self.location_code)
	 if location != nil 
		 self.location = location
		 return true
	 else
		errors.add_to_base("combination of: 'location_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_precool_job

	precool_job = PrecoolJob.find_by_location_id(self.location_id)
	 if precool_job != nil 
		 self.precool_job = precool_job
		 return true
	 else
		errors.add_to_base("value of field: 'location_id' is invalid- it must be unique")
		 return false
	end
end
 
def set_facility

	facility = Facility.find_by_facility_type_code_and_facility_code_and_id(self.facility_type_code,self.facility_code,self.id)
	 if facility != nil 
		 self.facility = facility
		 return true
	 else
		errors.add_to_base("combination of: 'facility_type_code' and 'facility_code' and 'id'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: location_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_location_codes

	location_codes = Location.find_by_sql('select distinct location_code from locations').map{|g|[g.location_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: facility_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_facility_type_codes

	facility_type_codes = Facility.find_by_sql('select distinct facility_type_code from facilities').map{|g|[g.facility_type_code]}
end



def self.get_all_facility_codes

	facility_codes = Facility.find_by_sql('select distinct facility_code from facilities').map{|g|[g.facility_code]}
end



def self.facility_codes_for_facility_type_code(facility_type_code)

	facility_codes = Facility.find_by_sql("Select distinct facility_code from facilities where facility_type_code = '#{facility_type_code}'").map{|g|[g.facility_code]}

	facility_codes.unshift("<empty>")
 end



def self.get_all_ids

	ids = Facility.find_by_sql('select distinct id from facilities').map{|g|[g.id]}
end



def self.ids_for_facility_code_and_facility_type_code(facility_code, facility_type_code)

	ids = Facility.find_by_sql("Select distinct id from facilities where facility_code = '#{facility_code}' and facility_type_code = '#{facility_type_code}'").map{|g|[g.id]}

	ids.unshift("<empty>")
 end






end
