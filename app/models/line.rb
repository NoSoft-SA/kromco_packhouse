class Line < ActiveRecord::Base

  belongs_to :production_resource
  belongs_to :line_config
  
  attr_writer :facility_id
  attr_reader :facility_id
  
  validates_presence_of :line_code
  validates_associated :production_resource
  
  def before_create
   
   #create the production resource
   prod_resource = ProductionResource.new
   facility = Facility.find(self.facility_id)
   prod_resource.facility = facility
   prod_resource.resource_type_code = "line"
   prod_resource.resource_code = facility.facility_code + "_" + self.line_code
   prod_resource.create
   self.production_resource = prod_resource
  
  end
  
  
   def before_update
   
    self.production_resource.resource_code = self.production_resource.facility.facility_code + "_" + self.line_code
    self.production_resource.save
   
   end
   
   def before_destroy
     self.production_resource.destroy
   
   end
   
   
   def Line.get_line_for_packhouse_and_line_code(packhouse_code,line_code)
     query = "SELECT public.lines.line_code,public.lines.id,public.lines.line_config_id
             FROM public.lines
             INNER JOIN public.production_resources ON (public.lines.production_resource_id = public.production_resources.id)
             INNER JOIN public.facilities ON (public.production_resources.facility_id = public.facilities.id)
             WHERE
            (public.facilities.facility_code = '#{packhouse_code}') AND 
            (public.facilities.facility_type_code = 'packhouse') and
            (public.lines.line_code = '#{line_code}')"
   
    
    line = Line.find_by_sql(query)[0]
   
   
   end
   
   
   
   def Line.lines_for_packhouse(packhouse_name,is_for_list = true)
   
     query = "SELECT 
             public.lines.line_code
             FROM public.lines
             INNER JOIN public.production_resources ON (public.lines.production_resource_id = public.production_resources.id)
             INNER JOIN public.facilities ON (public.production_resources.facility_id = public.facilities.id)
             WHERE
            (public.facilities.facility_code = '#{packhouse_name}') AND 
            (public.facilities.facility_type_code = 'packhouse')"
   
    
    lines = Line.find_by_sql(query)
    if is_for_list
      return lines.map{|l| [l.line_code]}
    else
      return lines
    end
   
   end
   
end
