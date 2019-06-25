class RebinGradingRule < ActiveRecord::Base

#  ===========================
#   Association declarations:
#  ===========================


  belongs_to :rebin_grading_rule_header

#  ============================
#   Validations declarations:
#  ============================
#  =====================
#   Complex validations:
#  =====================
# def validate
# #  first check whether combo fields have been selected
#    is_valid = true
#    if is_valid
#      is_valid = ModelHelper::Validations.validate_combos([{:created_at => self.created_at}],self)
#   end
#   #now check whether fk combos combine to form valid foreign keys
#    if is_valid
#      is_valid = set_rebin_grading_rule_header
#    end
# end

#  ===========================
#   foreign key validations:
#  ===========================
def set_rebin_grading_rule_header

  rebin_grading_rule_header = RebinGradingRuleHeader.find_by_created_at(self.created_at)
   if rebin_grading_rule_header != nil 
     self.rebin_grading_rule_header = rebin_grading_rule_header
     return true
   else
    errors.add_to_base("value of field: 'created_at' is invalid- it must be unique")
     return false
  end
end

#  ===========================
#   lookup methods:
#  ===========================



end