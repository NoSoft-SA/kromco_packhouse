class DeliveryDrenchStation < ActiveRecord::Base

    has_many :delivery_drench_concentrates
    belongs_to :drench_station
    
end