class BinTrackIndicator < ActiveRecord::Base

 belongs_to :bin

def validate
  is_valid = true
end
  
end