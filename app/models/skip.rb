class Skip < ActiveRecord::Base

 has_and_belongs_to_many :line_configs
 belongs_to :production_resource
 has_many :bays
 
  attr_writer :packhouse_code
  attr_reader :packhouse_code
  
  validates_presence_of :ip_address
  validates_presence_of :skip_code
  validates_presence_of :number_of_bays
  validates_uniqueness_of :skip_code
  
   def before_create
   
   #create the production resource
   prod_resource = ProductionResource.new
   facility = Facility.find_by_facility_code(self.packhouse_code)
   prod_resource.facility = facility
   prod_resource.resource_type_code = "skip"
   prod_resource.resource_code = facility.facility_code + "_" + self.skip_code
   prod_resource.create
   self.production_resource = prod_resource
  
  end
  
  
  def after_save
  
   for i in 1..self.number_of_bays
     if !Bay.find_by_bay_code_and_skip_id(i.to_s,self.id)
       bay = Bay.new
       bay.bay_code = i.to_s
       bay.skip = self
       bay.skip_ip = self.ip_address
       bay.create
     end
   end
  
  
  end
  
  
  
  def before_update
     facility = Facility.find_by_facility_code(self.packhouse_code)
     self.production_resource.resource_code = facility.facility_code + "_" + self.skip_code
     self.production_resource.save
  end
  
  def after_find
    self.packhouse_code = self.production_resource.facility.facility_code
  end
  
  
  def before_destroy
    self.production_resource.destroy
  end
 
end
