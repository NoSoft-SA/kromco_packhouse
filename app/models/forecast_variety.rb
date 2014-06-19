class ForecastVariety < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================


	belongs_to :forecast
	has_many :forecast_variety_indicators , :order => "track_slms_indicator_code"


#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :quantity
#	=====================
#	 Complex validations:
#	=====================
def validate
#	first check whether combo fields have been selected
	 is_valid = true
  if is_valid
   is_valid = ModelHelper::Validations.validate_combos([{:rmt_variety_code => self.rmt_variety_code}],self)
  end

  if is_valid
   is_valid = is_quantity_valid?
  end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_forecast
	 end
end

def is_quantity_valid?
  if(self.quantity > 0)
    return true
  end
  errors.add_to_base("quantity must be greater than zero")
  false
end
#	===========================
#	 foreign key validations:
#	===========================
def set_forecast

	#forecast = Forecast.find_by_season_code_and_farm_code_and_forecast_code_and_forecast_status_code(self.season_code,self.farm_code,self.forecast_code,self.forecast_status_code)
	forecast = Forecast.find(self.forecast_id)
	 if forecast != nil
		 self.forecast = forecast
		 return true
	 else
		errors.add_to_base("Please specify forecast for this variety indicator")
		 return false
	end
end

#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: forecast_id
#	------------------------------------------------------------------------------------------

def self.get_all_season_codes

	season_codes = Forecast.find_by_sql('select distinct season_code from forecasts').map{|g|[g.season_code]}
end



def self.get_all_farm_codes

	farm_codes = Forecast.find_by_sql('select distinct farm_code from forecasts').map{|g|[g.farm_code]}
end



def self.farm_codes_for_season_code(season_code)

	farm_codes = Forecast.find_by_sql("Select distinct farm_code from forecasts where season_code = '#{season_code}'").map{|g|[g.farm_code]}

	farm_codes.unshift("<empty>")
 end



def self.get_all_forecast_codes

	forecast_codes = Forecast.find_by_sql('select distinct forecast_code from forecasts').map{|g|[g.forecast_code]}
end



def self.forecast_codes_for_farm_code_and_season_code(farm_code, season_code)

	forecast_codes = Forecast.find_by_sql("Select distinct forecast_code from forecasts where farm_code = '#{farm_code}' and season_code = '#{season_code}'").map{|g|[g.forecast_code]}

	forecast_codes.unshift("<empty>")
 end



def self.get_all_forecast_status_codes

	forecast_status_codes = Forecast.find_by_sql('select distinct forecast_status_code from forecasts').map{|g|[g.forecast_status_code]}
end



def self.forecast_status_codes_for_forecast_code_and_farm_code_and_season_code(forecast_code, farm_code, season_code)

	forecast_status_codes = Forecast.find_by_sql("Select distinct forecast_status_code from forecasts where forecast_code = '#{forecast_code}' and farm_code = '#{farm_code}' and season_code = '#{season_code}'").map{|g|[g.forecast_status_code]}

	forecast_status_codes.unshift("<empty>")
 end

 def has_forecast_variety_indicator?(forecast_variety_indicator)
   if ForecastVarietyIndicator.find_by_track_slms_indicator_code_and_forecast_variety_id(forecast_variety_indicator.track_slms_indicator_code,self.id)
     return true
   end
   return false
 end
end
