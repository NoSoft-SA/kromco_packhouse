class MesscadaPeopleViewMesscadaRfidAllocation < ActiveRecord::Base

  #MM112014 - messcada changes
  belongs_to :messcada_rfid_allocation

  belongs_to :person

end