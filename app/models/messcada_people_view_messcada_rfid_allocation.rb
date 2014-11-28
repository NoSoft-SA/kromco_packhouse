class MesscadaPeopleViewMesscadaRfidAllocation < ActiveRecord::Base

  #MM112014 - messcada changes
  belongs_to :messcada_rfid_allocation

  belongs_to :person

  # validates_presence_of :rfid
  # validates_presence_of :person_id

  # def validate
  #   if self.new_record?
  #     validate_uniqueness
  #   end
  # end
  #
  # def validate_uniqueness
  #   exists = MesscadaPeopleViewMesscadaRfidAllocation.find_by_rfid_and_person_id(self.rfid,self.person_id)
  #   if exists != nil
  #     errors.add_to_base("There already exists a record with the combined values of fields: 'rfid' and 'person_id' ")
  #   end
  # end

end