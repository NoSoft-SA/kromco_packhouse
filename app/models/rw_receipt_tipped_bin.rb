class RwReceiptTippedBin < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 	belongs_to :rw_run
#	belongs_to :delivery
 
def RwReceiptTippedBin.receive_tipped_bin(tipped_bin,rw_run)
  
  received_bin = RwReceiptTippedBin.new
  tipped_bin.export_attributes(received_bin,true)
  received_bin.rw_run = rw_run
     #received_bin.rw_receipt_unit = "bin"  #Confirm Hans
  received_bin.create
   
  active_bin = RwActiveTippedBin.new
  tipped_bin.export_attributes(active_bin,true)
  active_bin.rw_run = rw_run
  active_bin.rw_reworks_action = "received"
     #received_bin.rw_receipt_unit = "bin"  #Confirm Hans
  active_bin.create
   
  return received_bin
end

end
