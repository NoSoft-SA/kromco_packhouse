class BinfillSortStation < ActiveRecord::Base

   belongs_to :line_config

   attr_accessor :rmt_product_code,
                :production_schedule_name,:production_run_number,:production_run_id
                
   @@rebin_links = nil

  def BinfillSortStation.set_rebin_links(links,run_id)
    
    @@rebin_links = Hash.new if ! @@rebin_links
    @@rebin_links[run_id] = links
  
  end
  
  
 def BinfillSortStation.clear_product_allocation_data(run_id)
   @@rebin_links.delete(run_id) if @@rebin_links
 end
 
 
  def BinfillSortStation.exists_for_line_config(config_id,station_code)
  
   query = "SELECT binfill_sort_stations.binfill_sort_station_code
           FROM
           public.binfill_sort_stations
           INNER JOIN public.line_configs ON (public.binfill_sort_stations.line_config_id = public.line_configs.id)
           WHERE
           (public.line_configs.id = '#{config_id}') AND 
           (public.binfill_sort_stations.binfill_sort_station_code = '#{station_code}')"
  
   return BinfillSortStation.find_by_sql(query)[0]
  
  end
  
   def BinfillSortStation.next_id(line_config_id)
  
   query = "SELECT max(binfill_sort_stations.gen_station_code)as maxval
           FROM
           public.binfill_sort_stations where 
           (binfill_sort_stations.line_config_id = '#{line_config_id}')"
           
   val = connection.select_one(query)
   if val["maxval"]== nil
     return 1
   else
    return val["maxval"].to_i + 1
   end
   
  end
  
  
  
  
  def set_product_context(run_id)
  
    
   if self.has_attribute?("line_code")
     line_code = self.attributes["line_code"].gsub("line","")
     self.binfill_sort_station_code = self.binfill_sort_station_code.gsub("x",line_code) 
   end
   
   #now see if we have an rmt match
    if @@rebin_links && @@rebin_links[run_id]
      link = @@rebin_links[run_id].find{|f|f.station_code == self.binfill_sort_station_code}
      self.rmt_product_code = link.rmt_product_code if link
    end
           
  end
end















