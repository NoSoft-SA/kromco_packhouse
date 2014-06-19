class CreateTripSheet < PDTTransaction
attr_accessor :scanned_bins,:tripsheet_number,:transaction_type, :delivery_number, :delivery_id

def initialize()
@scanned_bins = Array.new
@transaction_type = ""
@delivery_number  = ""

end


def create_tripsheet
  tripsheet_sequence_number =  MesControlFile.next_seq_web(26)
  @tripsheet_number = tripsheet_sequence_number

  next_state = ScanBinOnTrip.new(self)
  self.set_active_state(next_state)
return next_state.build_default_screen
end



end