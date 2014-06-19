class BinLocationSetup < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================


	belongs_to :location

#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :priority
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
		 is_valid = set_location
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
  def before_save
    self.commodity_code = "ALL" if(self.commodity_code.to_s.strip=='')
    self.season = "ALL" if(self.season.to_s.strip=='')
    self.rmt_product_code = "ALL" if(rmt_product_code.to_s.strip=='')
    self.track_slms_indicator_code = "ALL" if(track_slms_indicator_code.to_s.strip=='')
    self.farm_code = "ALL" if(farm_code.to_s.strip=='')
    self.rmt_product_type_code = "ALL" if(rmt_product_type_code.to_s.strip=='')
    self.treatment_code = "ALL" if(treatment_code.to_s.strip=='')
    self.product_class_code = "ALL" if(product_class_code.to_s.strip=='')
    self.ripe_point_code = "ALL" if(ripe_point_code.to_s.strip=='')
    self.size_code = "ALL" if(size_code.to_s.strip=='')
    self.assignment_code = "ALL" if(assignment_code.to_s.strip=='')
    self.rmt_variety_code = "ALL" if(rmt_variety_code.to_s.strip=='')
  end

def set_location

	location = Location.find(self.location_id)
	 if location != nil
		 self.location = location
		 return true
	 else
		errors.add_to_base("combination of: 'location_id'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================


end
