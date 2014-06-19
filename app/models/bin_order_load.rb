class BinOrderLoad < ActiveRecord::Base
  belongs_to :bin_order
  belongs_to :bin_load
  has_many   :bin_order_load_details

   def set_status(new_status)
     self.status = new_status
     self.update
   
   end

   def order_load_details_status?
    bin_order_load_details_status = BinOrderLoadDetail.find_by_sql("select status from bin_order_load_details where bin_order_load_details.bin_order_load_id = '#{self.id}'").map{|g|g.status}
    if  bin_order_load_details_status.include?("LOADING") || bin_order_load_details_status.include?("LOADED")||  bin_order_load_details_status.include?("COMPLETE")
      return "loading"
    else
      return "load_created"
    end

 end


end