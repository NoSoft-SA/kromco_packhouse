class LineConfig < ActiveRecord::Base

  has_and_belongs_to_many :bintip_stations
  has_many :drops, :dependent => :destroy,:order => "drop_code"
  has_and_belongs_to_many :carton_label_stations
  has_and_belongs_to_many :skips
  has_many :sublines, :dependent => :destroy
 
  has_many :binfill_sort_stations, :dependent => :destroy
  
end
