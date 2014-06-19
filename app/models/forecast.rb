class Forecast < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
#	belongs_to :season
	belongs_to :farm
	belongs_to :forecast_type
	has_and_belongs_to_many :track_slms_indicators
	has_many :forecast_varieties , :order => "commodity_code,rmt_variety_code"
	belongs_to :forecast_status
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :farm_code
	validates_presence_of :forecast_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:farm_code => self.farm_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_farm
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:season => self.season}],self)
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
#		 is_valid = set_season
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:forecast_type_code => self.forecast_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_forecast_type
     end

     if is_valid
		 is_valid = set_forecast_status
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
  exists = Forecast.find_by_forecast_code(self.forecast_code)
	 if exists != nil
		errors.add_to_base("There already exists a record with this forecast_code")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#def set_season
#
#	season = Season.find_by_season(self.season)
#	 if season != nil
#		 self.season = season
#		 return true
#	 else
#		errors.add_to_base("combination of: 'season'  is invalid- it must be unique")
#		 return false
#	end
#end
 
def set_farm

	farm = Farm.find_by_farm_code(self.farm_code)
	 if farm != nil 
		 self.farm = farm
		 return true
	 else
		errors.add_to_base("combination of: 'farm_code'  is invalid- it must be unique")
		 return false
	end
end

def set_forecast_status

	 forecast_status = ForecastStatus.find_by_forecast_status_code(self.forecast_status_code)
	 if forecast_status != nil
		 self.forecast_status = forecast_status
		 return true
	 else
		errors.add_to_base("forecast_status(#{self.forecast_status_code}) does not exist")
		 return false
	end
end

def set_forecast_type

	forecast_type = ForecastType.find_by_forecast_type_code(self.forecast_type_code)
	 if forecast_type != nil 
		 self.forecast_type = forecast_type
		 return true
	 else
		errors.add_to_base("value of field: 'forecast_type_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: season_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_seasons

	seasons = Season.find_by_sql('select distinct season from seasons').map{|g|[g.season]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: farm_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_farm_codes

	farm_codes = Farm.find_by_sql('select distinct farm_code from farms').map{|g|[g.farm_code]}
end


def add_track_slms_indicator(track_slms_indicator)
#  if !self.track_slms_indicators.include?(track_slms_indicator)
   self.track_slms_indicators.push(track_slms_indicator)
#  end
end

def has_forecast_variety?(forecast_variety)
  if ForecastVariety.find_by_forecast_id_and_commodity_code_and_rmt_variety_code(forecast_variety.forecast_id,forecast_variety.commodity_code,forecast_variety.rmt_variety_code)
    return true
  end
  return false
end


end
