class RwReceiptRebin < ActiveRecord::Base

   belongs_to :rebin
   belongs_to :production_run
   belongs_to :rw_run

   def RwReceiptRebin.receive_rebin(rebin,rw_run,received_rebin = nil)
   
   received_rebin = RwReceiptRebin.new
   rebin.export_attributes(received_rebin,true)
   received_rebin.transaction_date = rebin.transaction_date
   received_rebin.date_time_created = rebin.date_time_created
   received_rebin.rebin = rebin
   received_rebin.rw_run = rw_run
   received_rebin.rw_receipt_datetime = Time.now
   received_rebin.create
   #create a copy in rw_active_cartons
   active_rebin = RwActiveRebin.new
   received_rebin.export_attributes(active_rebin,true)
   active_rebin.transaction_date = rebin.transaction_date
   active_rebin.date_time_created = rebin.date_time_created
   active_rebin.rw_receipt_rebin = received_rebin
   active_rebin.reworks_action = "received"
   active_rebin.create
   return received_rebin
  end
end
