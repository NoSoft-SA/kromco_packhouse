class PalletProbeHistory < ActiveRecord::Base
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :job
	belongs_to :probe
	belongs_to :pallet
    
 
    has_many :pallet_probe_temp_histories, :dependent => :destroy


    


end
