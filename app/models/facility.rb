class Facility < ActiveRecord::Base
 
 
 def Facility.include_drop_code_in_station_code
   false
 end
 
 def Facility.active_pack_house

  facility = Facility.find_by_facility_code_and_facility_type_code("KROMCO_1","packhouse")
  raise "No default packhouse defined" if !facility
  return facility
 end
 
 belongs_to :organization
 belongs_to :facility_type
 has_many :production_resources,:dependent => :destroy
 has_many :locations,:dependent => :destroy

 validates_presence_of :facility_code
 validates_presence_of :facility_type_code
 validates_associated :organization
 validates_associated :facility_type
 validates_uniqueness_of :facility_code

  def Facility.get_packhouses
  
   return Facility.find_all_by_facility_type_code("packhouse")
  
  end

def validate 
#	first check whether combo fields have been selected
	 is_valid = true

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:facility_type_code => self.facility_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_facility_type_code
	 end
	
end

def set_facility_type_code
   facility_type = FacilityType.find_by_facility_type_code(self.facility_type_code)
   
   if facility_type != nil
     self.facility_type = facility_type
   else
     errors.add_to_base("combination of: 'facility_type_code'  is invalid- it must be unique")
		 return false
   end
end



end
