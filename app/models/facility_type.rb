class FacilityType < ActiveRecord::Base
 validates_presence_of :facility_type_code
 validates_uniqueness_of :facility_type_code
end
