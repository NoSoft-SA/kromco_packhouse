class RmtSampleReceipt < PDTTransaction
  attr_accessor :location_code, :num_transfered_pallets, :current_pallet_number, :total_pallets, :current_pallet_previous_location
  
 def initialize()
   @total_pallets = 3
   @num_transfered_pallets = 0
   @location_code = nil
   @current_pallet_number = nil
   @current_pallet_previous_location = nil
 end
#----------------------------------------------------------------
# overriding the default_state_class? in PDTTransaction to
# specify a default_state
#----------------------------------------------------------------
  def default_state_class?()
   "SampleTransferPallet"
 end
end