class ReworksProgressManager

  attr_reader :run_completion_stats,:rw_run,:is_completing
 #================================================================================================================================
 #This class manages the collection and storage of reworks run completion progress info.
 #A new instance of this class will either lookup an existing rw_run_completion_tasks record or create a new one and calculate
 #all the intended actions that will be done by the reworks complete run process.
 #An instance of this class is used by to reworks complete run process to send notifications of actions taking place. This class
 #will manage the persistence of such info to a rw_run_completion_tasks record.
 #=================================================================================================================================

  @@update_interval = 5

 
  
  #----------------------------------------------------------------------------------
  #The constructor will try to look up a rw_run_completion_tasks record. If found,
  #an instance will be stored as @run_completion_stats record. If not, a new instance
  #will be created (it's stats values will individually be calculated)
  #----------------------------------------------------------------------------------

  def no_required_actions?

    action_count = 0
    action_count += @run_completion_stats.bins_tipped_req
    action_count += @run_completion_stats.bins_scrapped_req
    action_count += @run_completion_stats.bins_reclassified_req
    action_count += @run_completion_stats.pallets_scrapped_req
    action_count += @run_completion_stats.pallets_reclassified_req
    action_count += @run_completion_stats.pallets_created_req
    action_count += @run_completion_stats.cartons_scrapped_req
    action_count += @run_completion_stats.cartons_created_req
    action_count += @run_completion_stats.cartons_reclassified_req
    action_count += @run_completion_stats.cartons_pallet_refs_changed_req
    action_count += @run_completion_stats.pallets_qc_resets_req
    action_count += @run_completion_stats.pallet_build_ups_req


    return action_count == 0
    
  end
  
   def is_complete?

    return false if  @run_completion_stats.bins_tipped_req > @run_completion_stats.bins_tipped_done
    return false if @run_completion_stats.bins_scrapped_req > @run_completion_stats.bins_scrapped_done
    return false if @run_completion_stats.bins_reclassified_req > @run_completion_stats.bins_reclassified_done
    return false if @run_completion_stats.pallets_scrapped_req > @run_completion_stats.pallets_scrapped_done
    return false if @run_completion_stats.pallets_reclassified_req > @run_completion_stats.pallets_reclassified_done
    return false if @run_completion_stats.pallets_created_req > @run_completion_stats.pallets_created_done
    return false if @run_completion_stats.cartons_scrapped_req > @run_completion_stats.cartons_scrapped_done
    return false if @run_completion_stats.cartons_created_req > @run_completion_stats.cartons_created_done
    return false if @run_completion_stats.cartons_reclassified_req > @run_completion_stats.cartons_reclassified_done
    return false if @run_completion_stats.cartons_pallet_refs_changed_req > @run_completion_stats.cartons_pallet_refs_changed_done
    return false if @run_completion_stats.cartons_pallet_refs_changed_req > @run_completion_stats.cartons_pallet_refs_changed_done
    return false if @run_completion_stats.cartons_pallet_refs_changed_req > @run_completion_stats.cartons_pallet_refs_changed_done
    return false if @run_completion_stats.pallet_build_ups_req > @run_completion_stats.pallet_build_ups_done

    return false if !@qc_calc_done

    return true

  end

   def any_committed_action?
    return true if  @run_completion_stats.bins_tipped_done > 0
    return true if @run_completion_stats.bins_scrapped_done > 0
    return true if @run_completion_stats.bins_reclassified_done > 0
    return true if @run_completion_stats.pallets_scrapped_done > 0
    return true if @run_completion_stats.pallets_reclassified_done > 0
    return true if @run_completion_stats.pallets_created_done > 0
    return true if @run_completion_stats.cartons_scrapped_done > 0
    return true if @run_completion_stats.cartons_created_done > 0
    return true if @run_completion_stats.cartons_reclassified_done > 0
    return true if @run_completion_stats.cartons_pallet_refs_changed_done > 0
    return true if @run_completion_stats.cartons_pallet_refs_changed_done > 0
    return true if @run_completion_stats.cartons_pallet_refs_changed_done > 0
    return true if @run_completion_stats.pallet_build_ups_done > 0

    return false 


     
   end

 def new_stats?
   @is_new_stats
 end

  def initialize(rw_run,overwrite = nil)
    @rw_run = rw_run
    @conn = rw_run.connection
    @run_completion_stats = nil


    if !overwrite
      @run_completion_stats = RwRunCompletionTask.find_by_rw_run_name(rw_run.rw_run_name)
    end
    
    if ! @run_completion_stats
      @is_new_stats = true
      @run_completion_stats = RwRunCompletionTask.new()
      #collect stats and create record
      @run_completion_stats.rw_run_name = rw_run.rw_run_name
      @run_completion_stats.bins_tipped_req = calc_bins_tipped_req
      @run_completion_stats.bins_tipped_done = 0
      @run_completion_stats.bins_scrapped_req = calc_bins_scrapped_req
      @run_completion_stats.bins_scrapped_done = 0
      @run_completion_stats.bins_reclassified_req = calc_bins_reclassified_req
      @run_completion_stats.bins_reclassified_done = 0
      @run_completion_stats.pallets_scrapped_req = calc_pallets_scrapped_req
      @run_completion_stats.pallets_scrapped_done = 0
      @run_completion_stats.pallets_created_req = calc_pallets_created_req
      @run_completion_stats.pallets_created_done = 0
      @run_completion_stats.pallets_reclassified_req = calc_pallets_reclassified_req
      @run_completion_stats.pallets_reclassified_done = 0
      @run_completion_stats.cartons_scrapped_req = calc_cartons_scrapped_req
      @run_completion_stats.cartons_scrapped_done = 0
      @run_completion_stats.cartons_created_req = calc_cartons_created_req
      @run_completion_stats.cartons_created_done = 0
      @run_completion_stats.cartons_reclassified_req = calc_cartons_reclassified_req
      @run_completion_stats.cartons_reclassified_done = 0
      @run_completion_stats.cartons_pallet_refs_changed_req = calc_carton_pallet_refs_req
      @run_completion_stats.cartons_pallet_refs_changed_done = 0
      @run_completion_stats.pallets_qc_resets_req = 0 #can only be calculated later(buildup and grade recalcs needed first)
      @run_completion_stats.pallets_qc_resets_done = 0
      @run_completion_stats.pallet_build_ups_req = calc_pallet_build_ups_required
      @run_completion_stats.pallet_build_ups_done = 0
      @run_completion_stats.create 
   
    end
    @event_queue = 0
  end

  def reset_stats
      @run_completion_stats.bins_tipped_done = 0
      @run_completion_stats.bins_scrapped_done = 0
      @run_completion_stats.bins_reclassified_done = 0
      @run_completion_stats.pallets_scrapped_done = 0
      @run_completion_stats.pallets_created_done = 0
      @run_completion_stats.pallets_reclassified_done = 0
      @run_completion_stats.cartons_scrapped_done = 0
      @run_completion_stats.cartons_created_done = 0
      @run_completion_stats.cartons_reclassified_done = 0
      @run_completion_stats.cartons_pallet_refs_changed_done = 0
      @run_completion_stats.pallets_qc_resets_done = 0
      @run_completion_stats.pallet_build_ups_done = 0
      @run_completion_stats.persist

  end

  def update_stats
    @run_completion_stats.is_completing = true
    @event_queue += 1
    if @event_queue == @@update_interval
      @run_completion_stats.update
      @event_queue = 0
    end
  end

  #----------------
  #progress events
  #----------------
  def event_bin_tipped
    @run_completion_stats.bins_tipped_done += 1
    update_stats
  end

  def event_bin_scrapped
    @run_completion_stats.bins_scrapped_done += 1
    update_stats
  end

  def event_pallet_built_up
    @run_completion_stats.pallet_build_ups_done += 1
    update_stats
  end

  def event_bin_reclassified
    @run_completion_stats.bins_reclassified_done += 1
    update_stats
  end

   def event_pallet_scrapped
    @run_completion_stats.pallets_scrapped_done += 1
    update_stats
  end
  
   def event_pallet_created
    @run_completion_stats.pallets_created_done += 1
    update_stats
  end

  def event_pallet_reclassified
    @run_completion_stats.pallets_reclassified_done += 1
    update_stats
  end

   def event_carton_scrapped
    @run_completion_stats.cartons_scrapped_done += 1
    update_stats
  end

   def event_carton_created
    @run_completion_stats.cartons_created_done += 1
    update_stats
  end

   def event_carton_reclassified
    @run_completion_stats.cartons_reclassified_done += 1
    update_stats
  end

   def event_carton_pallet_ref_changed
     @run_completion_stats.cartons_pallet_refs_changed_done += 1
   end

   def event_pallet_qc_reset
     @run_completion_stats.pallets_qc_resets_done += 1
   end

   def event_generic_action(action)
     @run_completion_stats.generic_action = action
     @run_completion_stats.update #forcing update
   end

   def clear
     @run_completion_stats.delete
   end


   #==================
   #STATS CALCULATIONS
   #==================


  def calc_bins_tipped_req
    #return  @rw_run.rw_active_tipped_bins.length()
    @conn.select_one("select count(*) as count from rw_active_bins where rw_run_id = #{@rw_run.id.to_s} and ( upper(reworks_action) = 'TIPPED' OR upper(reworks_action) = 'BULK_TIPPED')" )['count'].to_i
  end



   def calc_bins_scrapped_req
     query = "SELECT
            count(*) as count
            FROM
            public.rw_active_bins
            right outer JOIN public.rw_receipt_bins ON
           (public.rw_active_bins.rw_receipt_bin_id = public.rw_receipt_bins.id)
           where ( public.rw_active_bins.rw_receipt_bin_id is null AND
                  public.rw_receipt_bins.rw_run_id = '#{@rw_run.id.to_s}')"

     @conn.select_one(query)['count'].to_i


  end


   def calc_bins_reclassified_req
#     @conn.select_one("select count(*) as count from rw_active_rebins where rw_run_id = #{@rw_run.id.to_s} and upper(reworks_action) = 'RECLASSIFIED'" )['count'].to_i
      @conn.select_one("select count(*) as count from rw_active_bins where rw_run_id = #{@rw_run.id.to_s} and (upper(reworks_action) = 'RECLASSIFIED' or upper(reworks_action) = 'WEIGHT_CHANGED')" )['count'].to_i
   end





   def calc_pallets_scrapped_req
      query = "SELECT
               count(*) as count
            FROM
            public.rw_active_pallets
            right outer JOIN public.rw_receipt_pallets ON
           (public.rw_active_pallets.rw_receipt_pallet_id = public.rw_receipt_pallets.id)
           where ( public.rw_active_pallets.rw_receipt_pallet_id is null AND 
                  public.rw_receipt_pallets.rw_run_id = '#{@rw_run.id.to_s}')"

     @conn.select_one(query)['count'].to_i
   end

  

  def calc_pallets_created_req
    query = "select count(*) from rw_active_pallets where rw_run_id = '#{@rw_run.id.to_s}' and upper(reworks_action) = 'NEW_PALLET'"
    @conn.select_one(query)['count'].to_i
  end

  def calc_pallets_reclassified_req
    query = "select count(*) from rw_active_pallets where rw_run_id = '#{@rw_run.id.to_s}' and (upper(reworks_action) = 'RECLASSIFIED' OR upper(reworks_action) = 'ALT_PACKED')"
    @conn.select_one(query)['count'].to_i
  end

   def calc_cartons_scrapped_req

        query = "SELECT
           count(*)
            FROM
            public.rw_active_cartons
            right outer JOIN public.rw_receipt_cartons ON
           (public.rw_active_cartons.rw_receipt_carton_id = public.rw_receipt_cartons.id)
           where ( public.rw_active_cartons.rw_receipt_carton_id is null AND
                  public.rw_receipt_cartons.rw_run_id = '#{@rw_run.id.to_s}')"

       scrapped1 =  @conn.select_one(query)['count'].to_i
       
         query = "select count(*) from rw_active_cartons where rw_run_id = '#{@rw_run.id.to_s}' and (upper(rw_pallet_action) = 'REMOVED' OR upper(rw_pallet_action) = 'PALLET_SCRAPPED') "
        scrapped2 = @conn.select_one(query)['count'].to_i

      return scrapped1 + scrapped2


  end


   def calc_pallet_build_ups_required
     query = "select count(*) from rw_active_pallets where rw_run_id = '#{@rw_run.id.to_s}' and (reworks_action = 'received' OR reworks_action = 'reclassified')  AND build_up_balance <> 0 "
     @conn.select_one(query)['count'].to_i
   end

  def calc_cartons_created_req
        query = "select count(*) from rw_active_cartons where rw_run_id = '#{@rw_run.id.to_s}' and (upper(reworks_action) = 'ALT_PACKED' OR upper(reworks_action) = 'ALT_PACKED_FROM_CARTON') "
        @conn.select_one(query)['count'].to_i
  end

  def calc_cartons_reclassified_req
    query = "select count(*) from rw_active_cartons where rw_run_id = '#{@rw_run.id.to_s}' and upper(reworks_action) = 'RECLASSIFIED'"
    @conn.select_one(query)['count'].to_i
  end

  def calc_carton_pallet_refs_req
    query = "select count(*) from rw_active_cartons where rw_run_id = '#{@rw_run.id.to_s}' and upper(rw_pallet_action) = 'ADDED'"
    @conn.select_one(query)['count'].to_i
  end
   

  def calc_pallets_qc_resets
    @qc_calc_done = true
    query = "select count(*) from rw_active_pallets where rw_run_id = #{@rw_run.id.to_s} and UPPER(qc_status_code) = 'UNINSPECTED' AND upper(reworks_action) <> 'NEW_PALLET' AND upper(reworks_action) <> 'ALT_PACKED'"
    @conn.select_one(query)['count'].to_i
  end



end
