class RwReceiptNewBin < ActiveRecord::Base
  belongs_to :bin
   belongs_to :production_run
   belongs_to :rw_run
    
   def RwReceiptNewBin.receive_bin(bin,rw_run,received_bin = nil)

   received_bin = RwReceiptNewBin.new
   bin.export_attributes(received_bin,true)
   received_bin.transaction_date = bin.bin_receive_date_time
   #received_bin.date_time_created = bin.date_time_created
   received_bin.bin = bin
   received_bin.rw_run = rw_run
   received_bin.rw_receipt_datetime = Time.now
   received_bin.create
   #create a copy in rw_active_cartons
   active_bin = RwActiveBin.new
   received_bin.export_attributes(active_bin,true)
   active_bin.transaction_date = bin.bin_receive_date_time
   #active_bin.date_time_created = bin.date_time_created
   active_bin.rw_receipt_new_bin = received_bin
   active_bin.reworks_action = "received"
   active_bin.create
   return received_bin
  end
end
