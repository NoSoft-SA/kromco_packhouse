class RwRunCompletionTask 


  attr_accessor :rw_run_name,:bins_tipped_req,:bins_tipped_done,:bins_scrapped_req,:bins_scrapped_done,:bins_reclassified_req,:bins_reclassified_done,:pallets_scrapped_req,:pallets_scrapped_done,
                :pallets_created_req,:pallets_created_done,:pallets_reclassified_req,:pallets_reclassified_done,:cartons_scrapped_req,:cartons_scrapped_done,:cartons_created_req,
                :cartons_created_done,:cartons_reclassified_req,:cartons_reclassified_done,:cartons_pallet_refs_changed_req,:cartons_pallet_refs_changed_done,:pallets_qc_resets_req,
                :pallets_qc_resets_done,:generic_action,:error,:done,:is_completing,:pallet_build_ups_req,:pallet_build_ups_done

    @@root_folder = "tmp/rw_runs_stats/"

 

  def RwRunCompletionTask.find_by_rw_run_name(run_name)

     if File.exists?(@@root_folder + run_name + ".rws")
           File.open(@@root_folder + run_name + ".rws") do |f|
            return Marshal.load(f)
          end
     else
       return nil
     end
  end


  def done=(val)
    @is_completing = nil
    @done = true
  end
  

  def get_style_class(action,is_perc = nil)
   
    action_req_name = action + "_req"
    action_done_name = action + "_done"
    action_req = self.send(action_req_name)
    action_done = self.send(action_done_name)
    if action_req && action_req > 0
      if action_done > 0
        if action_done < action_req
          if is_perc
            return "active_perc_cell"
          else
            return "active_cell"
          end
        else
          return "completed_cell"
        end
      else
        return "todo_cell"
      end
    else
      return "na_cell"
    end
  end

   def get_progress_style(action)
     if get_style_class(action).index("active")
       return "visible"
     else
       return "hidden"
     end

  end




  def create
   persist
  end

  
  def update
    persist
  end

  def persist
     File.open(@@root_folder + self.rw_run_name + ".rws", "w+") do |f|
      Marshal.dump(self, f)
    end
  end

  def delete
    File.delete(@@root_folder + self.rw_run_name + ".rws")
  end



end
