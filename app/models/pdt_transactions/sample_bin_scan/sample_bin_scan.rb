#----------------------------------------------------------------
# This class represents the SampleBinScan pdt program/transaction
#----------------------------------------------------------------
class SampleBinScan < PDTTransaction
  attr_accessor :current_delivery_number, :total_bins_scanned, :number_of_full_bins_scanned, :number_of_half_bins_scanned, :required_bins
  def initialize()
    @total_bins_scanned = 0
    @number_of_full_bins_scanned = 0
    @number_of_half_bins_scanned = 0
    @required_bins = 5
  end
  
#----------------------------------------------------------------
# overriding the default_state_class? in PDTTransaction to
# specify a default_state
#----------------------------------------------------------------
  def default_state_class?()
    "EnterSampleDeliveryNumber" 
  end
  
end