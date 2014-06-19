class CartonSetupUpdateTimestamp < ActiveRecord::Base
  belongs_to :carton_setup
  
  
  def update_time
   curr_time = Time.now
   self.last_update_timestamp = curr_time
   self.save
  end
  
  
end
