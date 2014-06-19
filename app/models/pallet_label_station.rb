class PalletLabelStation < ActiveRecord::Base

  belongs_to :production_resource

  attr_writer :packhouse_code
  attr_reader :packhouse_code
  
  validates_presence_of :packhouse_code
  validates_presence_of :ip_address
  validates_presence_of :pallet_label_station_code
  validates_uniqueness_of :pallet_label_station_code
  
  def before_create
   
   #create the production resource
   prod_resource = ProductionResource.new
   facility = Facility.find_by_facility_code(self.packhouse_code)
   prod_resource.facility = facility
   prod_resource.resource_type_code = "pallet_label_station"
   prod_resource.resource_code = facility.facility_code + "_" + self.pallet_label_station_code
   prod_resource.create
   self.production_resource = prod_resource
  
  end
  
  
  def before_update
     facility = Facility.find_by_facility_code(self.packhouse_code)
     self.production_resource.resource_code = facility.facility_code + "_" + self.pallet_label_station_code
     self.production_resource.save
  end
  
  def after_find
    self.packhouse_code = self.production_resource.facility.facility_code
  
  end
  
  def before_destroy
    self.production_resource.destroy
  end

end
