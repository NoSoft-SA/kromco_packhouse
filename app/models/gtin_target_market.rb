class GtinTargetMarket < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :gtin
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :target_market_code
	validates_presence_of :gtin_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
end

end
