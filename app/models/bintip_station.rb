class BintipStation < ActiveRecord::Base
  
  validates_presence_of :bintip_station_code
  validates_presence_of :ip_address
  validates_uniqueness_of :bintip_station_code
  belongs_to :production_resource
  attr_writer :packhouse_code
  attr_reader :packhouse_code
  
   def before_create
   
   #create the production resource
   prod_resource = ProductionResource.new
   facility = Facility.find_by_facility_code(self.packhouse_code)
   prod_resource.facility = facility
   prod_resource.resource_type_code = "bintip_station"
   prod_resource.resource_code = facility.facility_code + "_" + self.bintip_station_code
   prod_resource.create
   self.production_resource = prod_resource
  
  end
  
  
  def before_update
     facility = Facility.find_by_facility_code(self.packhouse_code)
     self.production_resource.resource_code = facility.facility_code + "_" + self.bintip_station_code
     self.production_resource.save
  end
  
  def after_find
    self.packhouse_code = self.production_resource.facility.facility_code
  
  end
  
  def before_destroy
    self.production_resource.destroy
  end
  
  
end
