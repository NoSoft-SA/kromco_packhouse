class LoadVoyagePort < ActiveRecord::Base
  belongs_to  :load_voyage
  belongs_to  :voyage_port

  
  def  port_type_code
     @port_type = VoyagePortType.find(self.voyage_port_type_id).voyage_port_type_code if !@port_type
     return  @port_type

   end


   def  port_code
     @port_code = Port.find(self.port_id).port_code if !@port_code
     return  @port_code

   end

  



  
end