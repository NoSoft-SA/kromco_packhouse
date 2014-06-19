class RmtBin < ActiveRecord::Base
has_many :bin_track_indicators

def validate
  is_valid = true
end
  
end