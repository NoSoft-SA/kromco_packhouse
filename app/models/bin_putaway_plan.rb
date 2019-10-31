class BinPutawayPlan < ActiveRecord::Base

  serialize :bins_to_putaway
  serialize :bins_putaway_completed

  def BinPutawayPlan.is_on_a_putaway_plan?(bin_number)
    bins_to_putaway  = ActiveRecord::Base.connection.select_all("
                       select bins_to_putaway from bin_putaway_plans").map{|x|x['bins_to_putaway']}

    if !bins_to_putaway.empty? && bins_to_putaway[0].include?("#{bin_number}")
      return true
    else
      return nil
    end
  end



#  ============================
#   Validations declarations:
#  ============================
  validates_numericality_of :qty_bins_to_putaway
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
