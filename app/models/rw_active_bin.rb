class RwActiveBin < ActiveRecord::Base
    belongs_to :bin
    belongs_to :rw_run
    belongs_to :rw_receipt_bin
    belongs_to :production_run

    attr_accessor :bin_time_search,:farm_code,:production_schedule_name,:input_variety,:trans_date_from,:trans_date_to,:line_code,:pc_code,
                  :track_slms_indicator_code ,:track_indicator_code1 ,:track_indicator_code2,:track_indicator_code3, :track_indicator_code4,
                  :track_indicator_code5,:delivery_number,:rmt_product_code ,:production_run_rebin_code




     def set_child_weights
       return if self.weight <= 0
       bin = Bin.find_by_bin_number(self.bin.bin_number)
       bin.ps_mix_lots.each do |child|
         child.weight = child.weight_proportion * self.weight
         child.update
       end


     end


    def RwActiveBin.scrap(bins,reason,user)
       ActiveRecord::Base.transaction do

            for bin in bins
               bin.exit_ref ="scrapped"
              bin.exit_reference_date_time =Time.now
              scrap_bin = RwScrapBin.new
              bin.rw_receipt_bin.export_attributes(scrap_bin,true)
              scrap_bin.rw_reason_id = reason.id
              scrap_bin.user_name = user.user_name
              scrap_bin.exit_ref ="scrapped"
              scrap_bin.exit_reference_date_time =Time.now
              scrap_bin.create
              bin.destroy
            end
          end



    end





end
