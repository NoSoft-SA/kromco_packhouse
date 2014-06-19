class ProductionResource < ActiveRecord::Base

 belongs_to :resource
 belongs_to :facility

 has_one :line
 has_one :rebin_label_station
 has_one :pallet_label_station
 
 def before_create
   resource = Resource.new
   resource.resource_code = self.resource_code
   resource.resource_type_code = self.resource_type_code
   resource.create
   self.resource = resource
 
 end
 
 
 def before_update
   self.resource.resource_code = self.resource_code
   self.resource.save
 
 end
 
 def before_destroy
  self.resource.destroy
 
 end

end
