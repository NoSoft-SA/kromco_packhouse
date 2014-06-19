class CartonPackType < ActiveRecord::Base
  
  validates_presence_of :type_code
  validates_uniqueness_of :type_code
  
end
