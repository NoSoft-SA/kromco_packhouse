class DeliveryTrackIndicator < ActiveRecord::Base
  attr_accessor :variety_type, :starch_summary_results

  belongs_to :delivery
  belongs_to :track_slms_indicator

  validates_presence_of :track_indicator_type_code, :track_slms_indicator_code, :commodity_code, :season_code, :rmt_variety_code
  #validates_uniqueness_of :track_indicator_type_code

end