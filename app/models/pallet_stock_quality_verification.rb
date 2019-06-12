class PalletStockQualityVerification < ActiveRecord::Base

#  ===========================
#   Association declarations:
#  ===========================



#  ============================
#   Validations declarations:
#  ============================
  validates_presence_of :pallet_number
#  =====================
#   Complex validations:
#  =====================
def validate 
#  first check whether combo fields have been selected
   is_valid = true
  #validates uniqueness for this record
   if self.new_record? && is_valid
     validate_uniqueness
   end
end

def validate_uniqueness
   exists = PalletStockQualityVerification.find_by_pallet_number_and_created_by(self.pallet_number,self.created_by)
   if exists != nil 
    errors.add_to_base("There already exists a record with the combined values of fields: 'pallet_number' and 'created_by' ")
  end
end
#  ===========================
#   foreign key validations:
#  ===========================
#  ===========================
#   lookup methods:
#  ===========================



end
