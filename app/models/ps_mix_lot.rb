class PsMixLot < ActiveRecord::Base

    belongs_to :bin


   def weight_proportion
     if self.weight > 0
       return self.weight/self.bin.weight
     else
       return 0
     end

   end


end
