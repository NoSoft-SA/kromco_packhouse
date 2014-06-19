class CartonTemplate < ActiveRecord::Base
  belongs_to :carton_setup
  has_many :carton_links,:dependent => :destroy
end



