class ForecastVarietyIndicatorsTrackSlmsIndicator < ActiveRecord::Base

  belongs_to :forecast_variety_indicator
  belongs_to  :track_slms_indicator

  
end