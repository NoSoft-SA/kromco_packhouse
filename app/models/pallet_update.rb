class PalletUpdate
  
  
  attr_reader :puc_groups,:pallet
  attr_accessor :fg_carton,:override_reason,:user,:rw_pallet_id,:use_new_pallet,:total_count,:total_weight,:repr_carton,:total_req_amount
  #====================================================================================
  #This class manages the batch update of cartons- per production run group
  #It has to provide the following functions:
  #-> group cartons per production run- and store the groups
  #-> store the representative cartons, used as the base for the batch update
  #-> batch-update all cartons, belonging to each group, in a single transaction
  #-> FOR REPACK:
  #   -> Total the weight of each group of cartons (per production run) and work
  #      out the ratio of one to the other
  #   -> Calculate the weight ratio of the representative cartons and, given
  #      the total required amount of cartons, calculate the number of each
  #      group needed to adhere to the ratio and to total to the required
  #      amount of total cartons
  #   -> Delete the original cartons in active_cartons table, and create new copies
  #      for each each group + update the 'alt_packed_datetime' field of each receipt
  #      carton belonging to the pallet to be repacked
  #   -> Allow for the storage of user-defined overridden amounts of required cartons
  #      for each group  
  #====================================================================================
  def initialize(pallet,is_repack = nil)
    @pallet = pallet
    @puc_groups = Hash.new
    build_groups 
    calc_ratios if is_repack 
    
  end


  def build_groups
    puc_groups = get_puc_groups
   tot_count = 0
    puc_groups.each do |puc_group|
      group_details = Hash.new
      group_details[:representative_carton]= nil
      group_details[:cartons]= nil
      group_details[:cartons]= nil
      group_details[:run_id]= puc_group["production_run_id"]
      @puc_groups.store(puc_group["production_run_code"] + "__" + puc_group["farm_code"] + "__"  + puc_group["puc"]   ,group_details)
      group_details[:cartons]= RwActiveCarton.find_all_by_rw_active_pallet_id_and_rw_run_id_and_production_run_code_and_puc_and_farm_code(@pallet.id,@pallet.rw_run_id,puc_group["production_run_code"],puc_group['puc'],puc_group['farm_code'])
      tot_count += group_details[:cartons].length
   end
   self.total_count = tot_count
  end
  
  #------------------------------------------------------------------------------
  #This method can be used as a calculation only- i.e. to provide a preview
  #to the user of the amounts that will be created for each run group OR
  #as part of the commit phase of the repack (called internally from 'repack_pallet'
  #method
  #------------------------------------------------------------------------------
  def calc_amounts(total_amount_required,do_not_commit = nil)
     calc_amounts = nil
     self.total_req_amount = total_amount_required
     @ratios.each do |ratio|
       ratio_num = ratio[:ratio]
       req_amount = ((ratio_num)* total_amount_required).round
       
       if !do_not_commit
          @puc_groups[ratio[:puc_group]][:req_amount] = req_amount
       else
         calc_amounts = Hash.new if !calc_amounts
         calc_amounts.store(ratio[:puc_group],req_amount)
       end
     end
    return calc_amounts
  end
  
  #-----------------------------------------------------------------------
  #This method accepts user-defined new(overriden) amounts of cartons that
  #need to be created as a hash with keys being the run_code of each group
  #-----------------------------------------------------------------------
  def override_amounts(reason,new_amounts)
    self.override_reason = reason
    new_amounts.each do |run_code,amount|
      @puc_groups[run_code][:overridden_amount]= amount
    end
  
  end
  
  def calc_ratios
  
   @ratios = Array.new
   sum = 0.0
   @puc_groups.each do |puc_group_code,puc_group|
     @ratios[@ratios.length()]= Hash.new
     @ratios[@ratios.length()-1][:puc_group]= puc_group_code
     @ratios[@ratios.length()-1][:weight]= get_total_weight(puc_group)
     sum += @ratios[@ratios.length()-1][:weight]
     puc_group[:weight] = Float.round_float(2,@ratios[@ratios.length()-1][:weight])
     
   end
   
   self.total_weight = sum
   @ratios.each do |ratio|
    ratio[:ratio] = ratio[:weight]/sum
    @puc_groups[ratio[:puc_group]][:ratio]=  (ratio[:ratio]*100).to_s
   end 
   
   
  end


  def get_total_weight(puc_group)
   
   weight = 0
   puc_group[:cartons].each do |carton|
    weight += carton.carton_fruit_nett_mass
   end
   
   return weight.to_f
  
  end
  
  
  #------------------------------------------------------------------
  #This method uses the main group's representative carton to update
  #the fg-related state of all cartons on the pallet, without committing the state
  #changes to database
  #------------------------------------------------------------------
  def update_pallet_fg_data()
    @puc_groups.each do |key, puc_group|
      puc_group[:cartons].each do |carton|
        set_carton_fg_data(carton)
      end
     end
  end
  
   def set_carton_fg_data (carton)
        repr_carton = self.fg_carton
        carton.items_per_unit = repr_carton.items_per_unit
        carton.units_per_carton = repr_carton.units_per_carton
        carton.item_pack_product_code = repr_carton.item_pack_product_code
        carton.unit_pack_product_code = repr_carton.unit_pack_product_code
        carton.carton_pack_product_code = repr_carton.carton_pack_product_code
        carton.fg_product_code = repr_carton.fg_product_code
        carton.commodity_code = repr_carton.commodity_code
        carton.variety_short_long = repr_carton.variety_short_long
        carton.actual_size_count_code = repr_carton.actual_size_count_code
        carton.grade_code = repr_carton.grade_code
        carton.product_class_code = repr_carton.product_class_code
        carton.treatment_code = repr_carton.treatment_code
        carton.carton_fruit_nett_mass = repr_carton.carton_fruit_nett_mass
        carton.extended_fg_code = repr_carton.extended_fg_code

   end
  
  
  #--------------------------------------------------------------------------------------------------
  #This method assumes that, for each run group and in the order specified below:
  # 1) The newest state of each representative carton has been stored (via 'update_attributes_state'
  #    and 'store_representative_carton' methods
  #    FOR MULTI-RUN GROUPS:
  # 2) ratios have been calculated ('calc_ratios' method)
  # 3) amount of cartons required have been calculated, given the user specified total
  #    ('calc_amounts(total_amount_required)' method)
  #--------------------------------------------------------------------------------------------------
  def repack_pallet(req_amount = nil)
     #delete all the cartons, currently belonging to the pallet and create the
     #repacked cartons- each carton getting it's state from the representative
     #carton of the group, or if not specified from the main representative carton
     calc_amounts(req_amount) if req_amount
     new_pallet = nil
     @pallet.transaction do
       #---------------------------------------------------------------------------------
       #Set pallet and cartons' qc_status to 'UNINSPECTED' and result to nil
       #---------------------------------------------------------------------------------
       self.fg_carton.qc_status_code = "UNINSPECTED"
       self.fg_carton.qc_result_status = nil #fg carton's values will be propagated to all cartons on repacked  pallet
       @pallet.qc_status_code = "UNINSPECTED"
       @pallet.qc_result_status = nil
       
       now = Time.now.to_formatted_s(:db)
       RwReceiptCarton.update_all(ActiveRecord::Base.extend_set_sql_with_request("alt_packed_datetime = '#{now}'","rw_receipt_cartons"),"pallet_id = '#{@pallet.rw_receipt_pallet.id}' and rw_run_id = '#{@pallet.rw_receipt_pallet.rw_run_id}'")
       override_reason = nil
       if !self.use_new_pallet
         @pallet.rw_receipt_pallet.alt_packed_datetime = now
         @pallet.carton_quantity_actual = req_amount
         self.fg_carton.update_pallet(@pallet)
         @pallet.reworks_action = "ALT_PACKED"
         @pallet.carton_quantity_actual = req_amount
         @pallet.update
       else
         #@pallet.rw_receipt_pallet.alt_packed_detroyed_datetime = now
         new_pallet = RwActivePallet.find(self.rw_pallet_id)
         new_pallet.pallet_format_product_code = @pallet.pallet_format_product_code
         new_pallet.pallet_format_product_id = @pallet.pallet_format_product_id
         new_pallet.carton_quantity_actual = req_amount
         new_pallet.rw_receipt_pallet_id = nil
         new_pallet.update
       end
       
       @pallet.rw_receipt_pallet.update
       RwActiveCarton.delete_all("rw_active_pallet_id = '#{@pallet.id}' and rw_run_id = '#{@pallet.rw_run_id}'")
       
       @puc_groups.each do |run_code,puc_group|
         #-----------------------
         #delete original cartons
         #-----------------------
         puts "NEW GROUP"
         #--------------------------------------------------------------------------------------------------------
         #Create the required amount of new cartons- all copies from the clone, but with a different carton number
         #--------------------------------------------------------------------------------------------------------
         #new_sequence = MesControlFile.next_seq(1)
         req_amount = puc_group[:req_amount] if puc_group[:req_amount]
         if puc_group[:overridden_amount]
           req_amount = puc_group[:overridden_amount] 
           if !override_reason
             override_reason = RwAltPackOverride.new 
             override_reason.reason = self.override_reason
             override_reason.user = self.user.user_name
             override_reason.person = self.user.last_name + "," + self.user.first_name
             override_reason.amounts = run_code + ":[old = " + puc_group[:req_amount].to_s + "|new = " + puc_group[:overridden_amount].to_s + "]"
             override_reason.rw_receipt_pallet = @pallet.rw_receipt_pallet
             #@pallet.rw_receipt_pallet.rw_alt_pack_override = override_reason
             #@pallet.rw_receipt_pallet.update
           else
             override_reason.amounts += "," + run_code + ":[old = " + puc_group[:req_amount].to_s + "|new = " + puc_group[:overridden_amount].to_s + "]"
           end 
         end
         
         begin
           #raise " Group " + run_code + " has zero cartons. Every group must have at least one carton" if req_amount == 0
           req_amount = 1 if req_amount == 0
           num_series = RwRun.get_object_nums("CARTON",req_amount)
         rescue
           raise "New carton numbers could not be obtained. The following exception was reported: " + $!
         end
         
         for i in 1..req_amount
           new_sequence = num_series[i -1]#MesControlFile.next_seq(1)
           new_carton = RwActiveCarton.new 
           
           if puc_group[:representative_carton]
             puc_group[:representative_carton].export_attributes(new_carton,true,["carton_number"])
           else
            # conditions = "rw_active_pallet_id = #{@pallet.id} and rw_run_id = #{@pallet.rw_run_id} and production_run_code = '#{run_code}'"# (@pallet.id,@pallet.rw_run_id,run_code)
            # group_repr_carton = RwActiveCarton.find(:all,:conditions => "rw_active_pallet_id = '#{@pallet.id.to_s}' and rw_run_id = '#{@pallet.rw_run_id.to_s}' and production_run_id = '#{puc_group[:run_id].to_s}'")
            
             group_repr_carton = puc_group[:cartons][0]
             self.fg_carton.export_attributes(new_carton,true,["carton_number","production_run_code","farm_code","puc","track_indicator_code","production_run_id","bin_id","line_code"])
             new_carton.production_run_code = group_repr_carton.production_run_code
             new_carton.production_run_id = group_repr_carton.production_run_id
             new_carton.line_code = group_repr_carton.line_code
             new_carton.track_indicator_code = group_repr_carton.track_indicator_code
             new_carton.puc = group_repr_carton.puc
             new_carton.farm_code = group_repr_carton.farm_code
             new_carton.bin_id = group_repr_carton.bin_id
           end
           set_carton_fg_data(new_carton)#this will copy (and overwrite) all fg related data from the main 'fg_carton' for pallet
           new_carton.reworks_action = "alt_packed"
           new_carton.rw_receipt_carton_id = nil
           new_carton.rw_active_pallet_id = self.rw_pallet_id if self.use_new_pallet
           new_carton.pallet_number = new_pallet.pallet_number if self.use_new_pallet
           new_carton.carton_number = new_sequence
           new_carton.packer_number = "00241" 
           new_carton.create
           
         end
            puc_group[:cartons]= nil
       end
       override_reason.create if override_reason
       self.pallet.destroy if self.use_new_pallet
    
     end
     
  end
  
  
  
  def store_representative_carton(carton,production_run_code,is_not_repack = nil)

  if !@puc_groups.has_key?(production_run_code)

    #the carton's puc might have changed. In this case the production_run_code code need to be recalculated
    orig_puc = RwReceiptCarton.find_by_rw_run_id_and_carton_number(carton.rw_run_id,carton.carton_number)
    production_run_code = carton.production_run_code + "__" + carton.farm_code + "__" + orig_puc.puc

    if !@puc_groups.has_key?(production_run_code)
     raise ("The cartons of this pallet does not have a run called: #{production_run_code}<BR>. This will happen if the representative carton's run has a different farm_code or puc than the farm or puc <br>
                               stored on the carton")
    end

  end

    @puc_groups[production_run_code][:representative_carton]= carton
    if @puc_groups[production_run_code][:group_num]== 1
      self.fg_carton = carton
      #-------------------------------------------
      #update the fg related state of all cartons
      #-------------------------------------------
      if ! is_not_repack
        puts "updating fg on all groups"
        @puc_groups.each do |key,puc_group|
          puc_group[:cartons].each do |ctn|
            set_carton_fg_data(ctn)
          end
        end
      end
    end
  
  end
    
   #-------------------------------------------------------
   #This method assumes that the newest state(representative
   #cartons) has been stored
   #-------------------------------------------------------
   def update_pallet
     @pallet.transaction do
      
      self.fg_carton.update_pallet(@pallet)
      @pallet.reworks_action = "reclassified"

      @puc_groups.each do |key,puc_group|
        
        ctn_to_use = puc_group[:representative_carton]
        ctn_to_use = self.fg_carton if !puc_group[:representative_carton]
        
        update_group(ctn_to_use,puc_group) #if puc_group[:representative_carton]
        
      end

      @pallet.set_oldest_pack_date_time
      @pallet.update

    end
    
   end


   
   def update_group(representative_carton,puc_group)

     fields_not_to_copy = ["ppecb_inspection_id","shift_id","egap","carton_fruit_nett_mass_actual","date_time_created","date_time_erp_xmit","exit_date_time","rw_create_datetime","track_indicator_code","erp_cultivar","carton_number","carton_id","rw_receipt_carton_id","production_run_id","production_run_code","farm_code","puc","line_code","shift_code","carton_label_station_code","erp_station","erp_pack_point","carton_pack_station_code","is_inspection_carton","qc_datetime_out","qc_datetime_in","pick_reference","iso_week_code","pack_date_time","pc_code","qc_status_code","qc_result_status","packer_number","bin_id"]
     if  representative_carton.changed_fields?.has_key?('pick_reference')||representative_carton.changed_fields?.has_key?('pack_date_time')
       fields_not_to_copy.delete_if{|c|c == 'pack_date_time'|| c == 'pick_reference'}
     end

     puc_group[:cartons].each do |carton|
       representative_carton.export_attributes(carton,true,fields_not_to_copy)

       carton.reworks_action = "reclassified" if representative_carton.reworks_action != "alt_packed"
       carton.update
     end
   end
  
  
  def get_puc_groups
   query = "select distinct production_run_code,production_run_id,puc,farm_code from rw_active_cartons where rw_active_pallet_id = '#{@pallet.id}' and rw_run_id = '#{@pallet.rw_run_id}' order by production_run_code desc"
   return @pallet.connection.select_all(query)
  
  end


end
