class DepartmentMessage < ActiveRecord::Base
  belongs_to :department
  
  def before_update
   if !self.new_record?
    self.created_at = Time.now
   end
  end
  
  
end
