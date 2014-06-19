class RwReceiptCarton < ActiveRecord::Base
  
  belongs_to :carton
  belongs_to :rw_run
  belongs_to :rw_receipt_pallet
  belongs_to :carton_template
  
  attr_accessor :item_pack_product_code,:carton_pack_product_code,
                :calculated_mass,:target_market_short,
                :inventory_code_short,:pc_code_short
                
  
  
  def RwReceiptCarton.receive_carton(carton,rw_run,received_pallet = nil,no_pallet = nil)

   run_ti_sql = "SELECT
                rmt_setups.output_track_indicator_code
                 FROM
                public.production_schedules,
                public.production_runs,
                public.rmt_setups
                WHERE
                production_runs.production_schedule_id = production_schedules.id AND
                rmt_setups.production_schedule_id = production_schedules.id AND
                production_runs.id = #{carton.production_run_id}"

   run_ti = Carton.connection.select_one(run_ti_sql)['output_track_indicator_code']

   raise  "carton #{carton.carton_number} belongs to no pallet " if !carton.pallet_id

   plt = Pallet.find(carton.pallet_id.to_i)
   raise  "carton #{carton.carton_number} belongs to a pallet(#{carton.pallet_number}) that is still on a palletizing bay " if plt.process_status && plt.process_status.upcase.gsub("S","Z").index("PALLETIZING")


   #raise   "carton #{carton.carton_number} has an exit_ref(#{carton.exit_reference})" if carton.exit_reference

   #raise   "carton #{carton.carton_number} belongs to a pallet(#{plt.pallet_number}) with an exit_ref(#{plt.exit_ref})" if plt.exit_ref

   received_carton = RwReceiptCarton.new
   carton.export_attributes(received_carton,true)
   received_carton.run_track_indicator_code =   run_ti
   if carton.class.to_s == "Hash"
      received_carton.carton_id = carton['id'].to_i
   else
      received_carton.carton = carton
   end
   received_carton.rw_receipt_datetime = Time.now()
   received_carton.rw_run = rw_run
   if received_pallet
     received_carton.rw_receipt_pallet = received_pallet 
     received_carton.rw_receipt_unit = "pallet"
   else
     received_carton.rw_receipt_unit = "carton"
   end
   received_carton.create
   #create a copy in rw_active_cartons
   active_carton = RwActiveCarton.new
   received_carton.export_attributes(active_carton,true)
   active_carton.rw_receipt_carton = received_carton
   active_carton.reworks_action = "received"
   active_carton.rw_active_pallet = received_pallet.rw_active_pallet if received_pallet
   active_carton.rw_active_pallet_id = -1 if no_pallet
   #copy marking and diameter from extended_fg
    ext_fg_code = ""
    if carton.class.to_s == "Hash"
      ext_fg_code = carton['extended_fg_code']
    else
      ext_fg_code =carton.extended_fg_code
    end

    extended_fg = ExtendedFg.find_by_extended_fg_code(ext_fg_code)

    raise "carton(" + received_carton.carton_number.to_s + "). Extended fg record could not be found for extended fg code: " + ext_fg_code if ! extended_fg
    
    active_carton.marking = extended_fg.ru_description
    active_carton.diameter = extended_fg.ri_diameter_range
    active_carton.diameter = nil if active_carton.diameter && active_carton.diameter.strip == ""
    active_carton.diameter = extended_fg.ri_weight_range if !active_carton.diameter
    active_carton.create
   return received_carton
  end


  
  def decompose_fields
    #fg
    fg_code = FgProduct.find_by_fg_product_code(self.fg_product_code)
    self.item_pack_product_code = fg_code.item_pack_product_code
    puts "IPC: " + self.item_pack_product_code
    self.unit_pack_product_code = fg_code.unit_pack_product_code
    self.carton_pack_product_code = fg_code.carton_pack_product_code
    
    #target_market
    tm_vals = self.target_market_code.split("_")
    self.target_market_short = tm_vals[1]
    
    #inventory_code
    inv_vals = self.inventory_code.split("_")
    self.inventory_code_short = inv_vals[0]
  
  end
  
end
