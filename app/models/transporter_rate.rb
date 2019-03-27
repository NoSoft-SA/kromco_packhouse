class TransporterRate < ActiveRecord::Base

#  ===========================
#   Association declarations:
#  ===========================


  belongs_to :transporter
  belongs_to :city

#  ============================
#   Validations declarations:
#  ============================
  validates_presence_of :rate
#  =====================
#   Complex validations:
#  =====================
def validate 
#  first check whether combo fields have been selected
   is_valid = true
   if is_valid
     is_valid = ModelHelper::Validations.validate_combos([{:transporter_id => self.transporter_id}],self)
  end
  #now check whether fk combos combine to form valid foreign keys
   if is_valid
     is_valid = set_transporter
   end
   if is_valid
     is_valid = ModelHelper::Validations.validate_combos([{:city_id => self.city_id}],self)
  end
  #now check whether fk combos combine to form valid foreign keys
   if is_valid
     is_valid = set_city
   end
end

#  ===========================
#   foreign key validations:
#  ===========================
def set_transporter

  transporter = Transporter.find(self.transporter_id)
   if transporter != nil 
     self.transporter = transporter
     return true
   else
    errors.add_to_base("value of field: 'haulier_parties_role_id' is invalid- it must be unique")
     return false
  end
end

def set_city

  city = City.find(self.city_id)
   if city != nil 
     self.city = city
     return true
   else
    errors.add_to_base("combination of: 'city_code'  is invalid- it must be unique")
     return false
  end
end

#  ===========================
#   lookup methods:
#  ===========================
#  ------------------------------------------------------------------------------------------
#  Lookup methods for the foreign composite key of id field: city_id
#  ------------------------------------------------------------------------------------------

def city_code
  City.find(city_id).city_code
end






end
