class RwReceiptBin < ActiveRecord::Base
  belongs_to :bin
  belongs_to :production_run
  belongs_to :rw_run

  def RwReceiptBin.receive_bin(bins, rw_run, received_bin = nil)
    begin
    ActiveRecord::Base.transaction do
      for bin in bins
        received_bin = RwReceiptBin.new
        bin.export_attributes(received_bin, true)
        if bin.class.to_s == "Hash"
          received_bin.bin_id = bin['id'].to_i
        else
          received_bin.bin = bin
        end
        #received_bin.transaction_date = bin.bin_receive_date_time
        #TODO: received_bin.date_time_created = bin.bin_receive_date_time
        #received_bin.date_time_created = bin.bin_receive_date_time
        received_bin.rw_run = rw_run
        #received_bin.rw_receipt_datetime = Time.now
        received_bin.create
        #create a copy in rw_active_cartons
        active_bin = RwActiveBin.new
        received_bin.export_attributes(active_bin, true)
        #active_bin.transaction_date = bin.bin_receive_date_time
        #active_bin.date_time_created = bin.bin_receive_date_time
        active_bin.rw_receipt_bin = received_bin
        active_bin.reworks_action = "received"

        active_bin.create

      end
        return nil
    end
    rescue
      return $!
  end
end

end