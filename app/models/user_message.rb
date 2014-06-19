class UserMessage < ActiveRecord::Base
  belongs_to :user
  
   def before_update
   if !self.new_record?
    self.created_at = Time.now
   end
  end
  
end
