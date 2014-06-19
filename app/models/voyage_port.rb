class VoyagePort < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :voyage_port_type
	belongs_to :port
	belongs_to :voyage
    has_many :load_voyage_ports
 
#	============================
#	 Validations declarations:
#	============================

  validates_presence_of :quay

#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
     is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:port_id => self.port_id}],self,nil,true)
        set_port  if is_valid
     end


		 is_valid = ModelHelper::Validations.validate_combos([{:voyage_port_type_id => self.voyage_port_type_id}],self,nil,true)
    

	
end

def set_port

	port = Port.find_by_port_code(self.port_code)
	 if port != nil
		 self.port = port
		 return true
	 else
		errors.add_to_base("value of field: 'port_code' is invalid- it must be unique")
		 return false
	end
end
 

#	===========================
#	virtual attributes
#	===========================

  def  port_type_code
    @port_type = VoyagePortType.find(self.voyage_port_type_id).voyage_port_type_code if !@port_type
    return  @port_type

  end


  #def  port_code
  #@port_code = Port.find(self.port_id).port_code if !@port_code
  #return  @port_code
  #end



end
