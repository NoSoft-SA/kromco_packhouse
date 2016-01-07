class RmtVarietyQcLevel < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :season
	belongs_to :rmt_variety
	belongs_to :commodity_code	
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :sugar_min
	validates_presence_of :pressure_min
#	=====================
#	 Complex validations:
#	=====================


def validate_uniqueness
	 exists = RmtVarietyQcLevel.find_by_season_id_and_rmt_variety_id(self.season_id,self.rmt_variety_id)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'id' and 'season_id' and 'rmt_variety_id' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_season
    season = Season.find_by_season_code(self.season_code)
    if season != nil
        self.season = season
        return true
    else
        errors.add_to_base("combination of: 'season_code'  is invalid- it must be unique")
        return false
    end
end
 
def set_rmt_variety

	rmt_variety = RmtVariety.find_by_commodity_code_and_rmt_variety_code(self.commodity_code,self.rmt_variety_code)
	 if rmt_variety != nil 
		 self.rmt_variety = rmt_variety
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_code' and 'rmt_variety_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: season_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_season_codes

	season_codes = Season.find_by_sql('select distinct season_code from seasons').map{|g|[g.season_code]}
end




end
