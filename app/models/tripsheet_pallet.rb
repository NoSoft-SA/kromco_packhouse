class TripsheetPallet < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
  
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :position
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
end

#def get_tripsheet_pallet
#  if(pallet_validation = Marshal.load(self.pallet_validation)) #***
#    return pallet_validation                                               #***
#  end                                                                      #***
#  return self.pallet_number
#end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
