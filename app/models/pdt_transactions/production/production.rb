class Production < PDTTransaction
  #attr_accessor :location_code, :num_transfered_pallets, :current_pallet_number, :total_pallets, :current_pallet_previous_location

 def initialize()

 end
#----------------------------------------------------------------
# overriding the default_state_class? in PDTTransaction to
# specify a default_state
#----------------------------------------------------------------
 def default_state_class?()
   "RunStat"
 end
  
end