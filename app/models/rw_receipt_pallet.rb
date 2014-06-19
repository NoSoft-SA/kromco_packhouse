class RwReceiptPallet < ActiveRecord::Base

   belongs_to :pallet
   belongs_to :rw_run
   has_one :rw_active_pallet
   has_many :rw_receipt_cartons
   has_one :rw_alt_pack_override,:dependent => :destroy
   
   
   def RwReceiptPallet.receive_pallet(pallet,rw_run)
    n_cartons = 0
    already_received = 0
    #self.transaction do
      
      received_pallet = RwReceiptPallet.new
      pallet.export_attributes(received_pallet,true)
      received_pallet.pallet = pallet
      received_pallet.rw_run = rw_run
      received_pallet.rw_receipt_datetime = Time.now
      received_pallet.create
      active_pallet = RwActivePallet.new
      received_pallet.export_attributes(active_pallet,true)
      active_pallet.rw_receipt_pallet = received_pallet
      active_pallet.reworks_action = "received"
      active_pallet.create
      #------------------------------------------------
      #Receive all cartons belonging to received pallet
      #------------------------------------------------
      pallet.cartons.each do |carton|
       if !carton.exit_reference ||(carton.exit_reference && carton.exit_reference.upcase != "SCRAPPED")
          if receipt_carton = RwReceiptCarton.find_by_carton_number_and_rw_run_id(carton.carton_number,rw_run.id)
            already_received += 1
            receipt_carton.rw_receipt_pallet = received_pallet
            receipt_carton.update
          else
           received_carton = RwReceiptCarton.receive_carton(carton,rw_run,received_pallet)
            n_cartons += 1
          end
       end
     end
    #end
    
    return [n_cartons,already_received]
    
  end
   
end
