class Todo < ActiveRecord::Base

  
  validates_presence_of :description
  validates_presence_of :complete_by
  
  
end
