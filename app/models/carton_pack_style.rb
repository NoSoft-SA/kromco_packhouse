class CartonPackStyle < ActiveRecord::Base
  
  validates_presence_of :carton_pack_style_code
  validates_uniqueness_of :carton_pack_style_code
  
end
