class StarchSummaryResult < ActiveRecord::Base

#  ===========================
#   Association declarations:
#  ===========================


  belongs_to :delivery
#  =====================
#   Complex validations:
#  =====================
def validate 
#  first check whether combo fields have been selected
   is_valid = true

  #now check whether fk combos combine to form valid foreign keys
   if is_valid
     is_valid = set_delivery
   end
  #validates uniqueness for this record
   if self.new_record? && is_valid
     validate_uniqueness
   end
end

def validate_uniqueness
   exists = StarchSummaryResult.find_by_delivery_id(self.delivery_id)
   if exists != nil 
    errors.add_to_base("There already exists a record with the combined values of fields: 'delivery_id' ")
  end
end
#  ===========================
#   foreign key validations:
#  ===========================
def set_delivery

  delivery = Delivery.find(self.delivery_id)
   if delivery != nil 
     self.delivery = delivery
     return true
   else
    errors.add_to_base("combination of: 'delivery'  is invalid- it must be unique")
     return false
  end
end
end
