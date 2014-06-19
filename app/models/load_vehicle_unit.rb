class LoadVehicleUnit < ActiveRecord::Base

  belongs_to  :load_vehicle
  belongs_to  :pallet

def validate
  is_valid = true
end

end