class TrackIndicator < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :track_indicator_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = TrackIndicator.find_by_track_indicator_code(self.track_indicator_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'track_indicator_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
