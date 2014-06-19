class LoadVoyage < ActiveRecord::Base 

 attr_accessor :load_number  

#	===========================
# 	Association declarations:
#	===========================

	belongs_to :load
	belongs_to :voyage
  has_many  :load_voyage_ports, :dependent => :destroy


#	===========================
#	validations of text boxes
#	===========================

    validates_presence_of :booking_reference
    validates_uniqueness_of  :load_id
                                                    


#	===============================
#	Complex validations for combos
#	===============================
   def validate
	 is_valid = true
	 if is_valid
       is_valid = ModelHelper::Validations.validate_combos([{:load_id => self.load_id}],self,nil,true)
     end
     if is_valid
       is_valid = ModelHelper::Validations.validate_combos([{:shipping_agent_party_role_id => self.shipping_agent_party_role_id}],self,nil,true)
     end

     if is_valid
       is_valid = ModelHelper::Validations.validate_combos([{:exporter_party_role_id => self.exporter_party_role_id}],self,nil,true)
     end

       if is_valid
       is_valid = ModelHelper::Validations.validate_combos([{:shipper_party_role_id => self.shipper_party_role_id}],self,nil,true)
     end

        if is_valid
       is_valid = ModelHelper::Validations.validate_combos([{:shipping_line_party_id => self.shipping_line_party_id}],self,nil,true)
     end
     
   end


#===========================
# virtual attributes
#===========================
 def  exporter
  @exporter = PartiesRole.find(self.exporter_party_role_id).party_name if !@exporter
  return  @exporter

 end


 def shipping_agent
   @shipping_agent = PartiesRole.find(self.shipping_agent_party_role_id).party_name if !@shipping_agent
   return @shipping_agent
 end


 def shipper
   @shipper = PartiesRole.find(self.shipper_party_role_id).party_name if !@shipper
   return @shipper
 end


 def shipping_line
  @shipping_line = PartiesRole.find(self.shipping_line_party_id).party_name if !@shipping_line
  return @shipping_line
 end



 def load_number
   @load_number = Load.find(self.load_id).load_number if !@load_number
   return @load_number
 end

 def  port_type_code
     @port_type = VoyagePortType.find(self.voyage_port_type_id).voyage_port_type_code if !@port_type
     return  @port_type
  end

 def  port_code
     @port_code = Port.find(self.port_id).port_code if !@port_code
     return  @port_code

 end

end
