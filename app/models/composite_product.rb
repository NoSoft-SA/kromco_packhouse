class CompositeProduct < ActiveRecord::Base

 belongs_to :product, :dependent => :destroy
 
 def after_find
  self.quantity = 1 if !self.quantity||self.quantity == 0
 end
 
 def before_create
  self.quantity = 1 if !self.quantity||self.quantity == 0
 end
 
 def before_update
 
 
 end
 
end

