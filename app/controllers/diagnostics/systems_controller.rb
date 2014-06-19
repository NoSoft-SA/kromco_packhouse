class  Diagnostics::SystemsController < ApplicationController

 def program_name?
	"diagnostics"
 end

 def bypass_generic_security?
	true
 end
 

 def overall
 if request.post?
   
   session[:view_date] =  Date.civil(params[:date][:"view(1i)"].to_i,params[:date][:"view(2i)"].to_i,params[:date][:"view(3i)"].to_i).strftime("%Y-%m-%d")    

   session[:today] = session[:view_date]
   session[:tomorrow] = Date.civil(params[:date][:"view(1i)"].to_i,params[:date][:"view(2i)"].to_i,(params[:date][:"view(3i)"].to_i+1)).strftime("%Y-%m-%d")
  else
   session[:view_date] =  Time.now.strftime("%Y-%m-%d")

   session[:today] = session[:view_date]
   session[:tomorrow] = 1.day.from_now.strftime("%Y-%m-%d")
  end
   puts "nazi"
   puts params[:date]
   
   render :inline => %{
                       <script>
                         if(confirm("This report may take several minutes to load. \\n Are you sure you want to view report?") == true)
                            window.location = "/diagnostics/systems/render_system_overview_report";
                         else
                            window.location = "/diagnostics/systems/cancel_system_overview_report_rendering";
                         end
                       </script>}
end
 
 def cancel_system_overview_report_rendering
   render:inline => %{}, :layout => "content"
 end
 
 def render_system_overview_report
 
   @view_date = session[:view_date]
   @today = session[:today]
   @tomorrow = session[:tomorrow] 
   

   
   
#*****************Daily Avtivity Queries***********************************************
   @total_cartons_printed = Diagnostics.total_cartons_printed(@today,@tomorrow)
   @total_cartons_packed = Diagnostics.total_cartons_packed(@today,@tomorrow)
   @total_pallets_palletized =  Diagnostics.total_pallets_palletized(@today,@tomorrow)
   @total_bins_tipped = Diagnostics.total_bins_tipped(@today,@tomorrow)
   @total_rebins_printed = Diagnostics.total_rebins_printed(@today,@tomorrow)
   
   scan_total = @total_cartons_packed + @total_cartons_printed + @total_bins_tipped + @total_rebins_printed
   @total_number_of_scans = scan_total + (0.07 * scan_total)
   
#*****************productivity formulae***********************************************
   @scan_per_hour = Float.round_float(3,@total_number_of_scans / 9)
   @scans_per_minute = Float.round_float(2,(@scan_per_hour / 60))

#*****************error activity Queries***********************************************
   @server_errors = Diagnostics.server_errors(@today,@tomorrow)
   if(@server_errors > 0)
     @error_frequency =(@total_number_of_scans / @server_errors).to_i
   else
     @error_frequency = 0
   end
   
   if(@total_number_of_scans > 0)
      @error_percentage = Float.round_float(3,((@server_errors / @total_number_of_scans) * 100))
   else
      @error_percentage = 0
   end
   
#*****************reworks activity Queries***********************************************
   @cartons_scraped  = Diagnostics.cartons_scraped(@today,@tomorrow)
   if(@total_cartons_packed > 0)
     @cartons_scraped_percentage = Float.round_float(3,((@cartons_scraped / @total_cartons_packed.to_f )* 100))
   else
      @cartons_scraped_percentage = 0
   end
   
   @cartons_repacked  = Diagnostics.cartons_repacked(@today,@tomorrow)
   if(@total_cartons_packed > 0)
     @cartons_repacked_percentage = Float.round_float(3,((@cartons_repacked / @total_cartons_packed.to_f)* 100))
   else
      @cartons_repacked_percentage = 0
   end
   
   @cartons_reclassified  = Diagnostics.cartons_reclassified(@today,@tomorrow)
   if(@total_cartons_packed > 0)
     @cartons_reclassified_percentage = Float.round_float(3,((@cartons_reclassified / @total_cartons_packed.to_f)* 100))
   else
      @cartons_reclassified_percentage = 0
   end
   
   @pallets_scrapped  = Diagnostics.pallets_scrapped(@today,@tomorrow)
   if(@total_pallets_palletized > 0)
     @pallets_scrapped_percentage = Float.round_float(3,((@pallets_scrapped / @total_pallets_palletized.to_f)* 100))
   else
      @pallets_scrapped_percentage = 0
   end
   
   @pallets_reclassified  = Diagnostics.pallets_reclassified(@today,@tomorrow)
   if(@total_pallets_palletized > 0)
     @pallets_reclassified_percentage = Float.round_float(3,((@pallets_reclassified / @total_pallets_palletized.to_f )* 100))
   else
      @pallets_reclassified_percentage = 0
   end
   
   @pallets_repacked  = Diagnostics.pallets_repacked(@today,@tomorrow)
   if(@total_pallets_palletized > 0)
     @pallets_repacked_percentage = Float.round_float(3,((@pallets_repacked / @total_pallets_palletized.to_f )* 100))
   else
      @pallets_repacked_percentage = 0
   end
   
   @rebins_scraped  = Diagnostics.rebins_scraped(@today,@tomorrow)
   if(@total_rebins_printed > 0)
     @rebins_scraped_percentage = Float.round_float(3,((@rebins_scraped / @total_rebins_printed.to_f )* 100))
   else
      @rebins_scraped_percentage = 0
   end
   
   @rebins_reclassified  = Diagnostics.rebins_reclassified(@today,@tomorrow)
   if(@total_rebins_printed > 0)
     @rebins_reclassified_percentage = Float.round_float(3,((@rebins_reclassified / @total_rebins_printed.to_f )* 100))
   else
      @rebins_reclassified_percentage = 0
   end
      render :template => "diagnostics/systems/overall", :layout => "content"
 end
 
end