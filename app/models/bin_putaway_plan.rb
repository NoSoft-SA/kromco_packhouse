class BinPutawayPlan < ActiveRecord::Base

  serialize :bins_to_putaway
  serialize :bins_putaway_completed

  def BinPutawayPlan.is_on_a_putaway_plan?(bin_number)
    bins_to_putaway  = ActiveRecord::Base.connection.select_all("
                       select bins_putaway_completed from bin_putaway_plans").map{|x|x['bins_putaway_completed']}.delete_if { |e| e == nil}

    if !bins_to_putaway.empty? && bins_to_putaway.join(",").include?("#{bin_number}")
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
