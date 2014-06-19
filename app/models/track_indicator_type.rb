class TrackIndicatorType < ActiveRecord::Base
    has_many :track_slms_indicators
    
    def self.get_all_track_indicator_type_codes

	track_indicator_type_codes = TrackIndicatorType.find_by_sql('select distinct track_indicator_type_code from track_indicator_types').map{|g|[g.track_indicator_type_code]}
end
end