class Vessel < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================

   has_many :voyages
 
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :vessel_registration_number
	validates_presence_of :vessel_code
    validates_uniqueness_of :vessel_code
    
#	=====================
#	 Complex validations:
#	=====================
 def validate
 #	first check whether combo fields have been selected
	 is_valid = true
     ModelHelper::Validations.validate_combos([{:owner_party_role_id => self.owner_party_role_id}],self,nil,true)
    

 end

#	===========================
#	virtual attributes
#	===========================
  def vessel_owner
    @vessel_owner = PartiesRole.find(self.owner_party_role_id).party_name if !@vessel_owner
    return @vessel_owner
  end



end
