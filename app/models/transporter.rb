class Transporter < ActiveRecord::Base
   belongs_to :parties_role, :foreign_key => 'haulier_parties_role_id'

#  ===========================
#   Association declarations:
#  ===========================



#  ============================
#   Validations declarations:
#  ============================
#  =====================
#   Complex validations:
#  =====================
def validate 
#  first check whether combo fields have been selected
   is_valid = true
end

#  ===========================
#   foreign key validations:
#  ===========================
#  ===========================
#   lookup methods:
#  ===========================



end
