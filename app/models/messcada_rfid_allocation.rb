class MesscadaRfidAllocation < ActiveRecord::Base

  #MM112014 - messcada changes
  has_many :messcada_people_view_messcada_rfid_allocations#, :dependent => :destroy

end