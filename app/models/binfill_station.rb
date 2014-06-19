class BinfillStation < ActiveRecord::Base


 belongs_to :drop
 validates_presence_of :binfill_station_code
 validates_associated :drop
 
  attr_accessor :size,:color_percentage,:grade,:marketing_variety,
                :drop_code,:table_code,:rmt_product_code,
                :production_schedule_name,:production_run_number,:production_run_id,
                :additional_groups,:more_groups,:pack_group,:fg_product_code,:carton_setup_code
 
 
  @@outlets = nil
  @@rebin_links = nil
  #@@production_run_id = nil
  @@pack_id_outlets = nil
 
 
 def BinfillStation.is_alpha_numeric
  return true
 
 end
 
 def BinfillStation.clear_product_allocation_data(run_id)
   @@outlets.delete(run_id) if @@outlets
   @@rebin_links.delete(run_id) if @@rebin_links
   @@pack_id_outlets.delete(run_id) if @@pack_id_outlets
 end
 
 def has_allocated_outlet?
   match = false
#  if @@outlets && @@outlets != nil && self.has_attribute?("drop_code")
#     
#      match = @@outlets.find{|r|r.outlet1 == self.drop_code ||r.outlet2 == self.drop_code ||r.outlet3 == self.drop_code ||r.outlet4 == self.drop_code||r.outlet5 == self.drop_code ||r.outlet6 == self.drop_code}
#  end
  
  if self.color_percentage 
   match = true if self.color_percentage.to_i > -1
  end
  
  return match
 end
 
   def BinfillStation.exists_for_line_config(config_id,station_code)
  
   query = "SELECT binfill_stations.binfill_station_code
           FROM
           public.binfill_stations
           INNER JOIN public.drops ON (public.binfill_stations.drop_id = public.drops.id)
           INNER JOIN public.line_configs ON (public.drops.line_config_id = public.line_configs.id)
           WHERE
           (public.line_configs.id = '#{config_id}') AND 
           (public.binfill_stations.binfill_station_code = '#{station_code}')"
  
   return BinfillStation.find_by_sql(query)[0]
  
  end
 
 #---------------------------------------------------------------------------------------
  #This static method is used to set outlets for the run- outlets(associated
  #with pack_groups)Each outlet record contains fields outlets1 to 6, the values 
  #of which contain drop codes. So, an instance of binfill_station can search
  #the outlet records for a drop match in one of the outlet fields. Once that is
  #found, it can obtain the pack_group associated info: color_sort%,grade_code,size_count
  #----------------------------------------------------------------------------------------
  def BinfillStation.set_outlets(outlets,run_id)
    
    @@outlets = Hash.new if !@@outlets
    @@outlets[run_id] = outlets
    #-------------------------------
    #set pack groups if non-existing
    #-------------------------------
    BinfillStation.set_cross_product_pack_groups_ids(run_id)
  end
  
  def BinfillStation.set_rebin_links(links,run_id)
    @@rebin_links = Hash.new if !@@rebin_links
    @@rebin_links[run_id] = links
  
  end
  
  
#   def BinfillStation.set_production_run_id(run_id)
#  
#    @@production_run_id = run_id
#  
#  end
  
  
  def set_product_context(run_id)
  
    
    if self.has_attribute?("drop_code")
      self.drop_code = self.attributes["drop_code"]
    end
    
    
   if self.has_attribute?("line_code")
     line_code = self.attributes["line_code"].gsub("line","")
     self.binfill_station_code = self.binfill_station_code.gsub("x",line_code) 
   end
   
   #--------------------------------------------------------------------------------------------------------------------
   #Populate fields size_count,grade,marketing_variety
   #if a matching outlet_record can be found- outlets alraedy filtered for the line belonging to current production run 
   #--------------------------------------------------------------------------------------------------------------------
    
    if @@outlets && @@outlets[run_id] && self.has_attribute?("drop_code")
     
      match = @@outlets[run_id].find{|r|r.outlet1 == self.drop_code ||r.outlet2 == self.drop_code ||r.outlet3 == self.drop_code ||r.outlet4 == self.drop_code||r.outlet5 == self.drop_code ||r.outlet6 == self.drop_code||r.outlet7 == self.drop_code||r.outlet8 == self.drop_code||r.outlet9 == self.drop_code||r.outlet10 == self.drop_code||r.outlet11 == self.drop_code||r.outlet12 == self.drop_code}
      if match 
        
        puts "match id: " + match.id.to_s + " size: " + match.size_code.to_s
        self.color_percentage = match.pack_group.color_sort_percentage.to_s
        self.grade = match.pack_group.grade_code
        self.size = match.size_code
        self.marketing_variety = match.pack_group.marketing_variety_code
        
        #----------------------------------------------------------------------------------------
        #try to find other outlets that match this stations's drop code- this is possible, since 
        #a user can allocate a given drop to a given size from more than one group context
        #----------------------------------------------------------------------------------------
        @@outlets[run_id].each do |outlet|
          if outlet.outlet1 == self.drop_code ||outlet.outlet2 == self.drop_code ||outlet.outlet3 == self.drop_code ||outlet.outlet4 == self.drop_code||outlet.outlet5 == self.drop_code ||outlet.outlet6 == self.drop_code||outlet.outlet7 == self.drop_code||outlet.outlet8 == self.drop_code||outlet.outlet9 == self.drop_code||outlet.outlet10 == self.drop_code||outlet.outlet11 == self.drop_code||outlet.outlet12 == self.drop_code
            if outlet.pack_group.color_sort_percentage != self.color_percentage && outlet.pack_group.grade_code != self.grade
              
              self.additional_groups = Array.new if !self.additional_groups
               self.additional_groups.push [outlet.pack_group.color_sort_percentage,outlet.pack_group.grade_code]
            end
          end
        end
        
        #now see if we have an rmt match
        #if @@rebin_links
#          puts "prod_run_id: " + match.production_run_id.to_s
#          puts "station code: " + self.binfill_station_code.to_s
#          link = RebinLink.find_by_production_run_id_and_station_code(match.production_run_id,self.binfill_station_code)
#          #link = @@rebin_links.find{|f|f.production_run_id == match.production_run_id && f.station_code == self.binfill_station_code}
#          self.rmt_product_code = link.rmt_product_code if link
#          puts "link found: " + self.rmt_product_code if link
        #end
        
   
      end
      
    end
    
    #---------------------------------------------------------------
    #FOR REBINS ALL LINKS ARE ENABLED REGARDLESS OF DROP ALLOCATION!
    #that's why the 3 lines of code below was moved to where it is now
    # else 
    #---------------------------------------------------------------
    
      link = RebinLink.find_by_production_run_id_and_station_code(run_id,self.binfill_station_code)
      #link = @@rebin_links.find{|f|f.production_run_id == match.production_run_id && f.station_code == self.binfill_station_code}
      self.rmt_product_code = link.rmt_product_code if link
     
    #------------------------------------------------------------------------------------
    #FOR CROSS PRODUCT ALLOCATION: i.e. allocating a fg product to a binfill station
    # Get the first pack group from within which a 'std size count value' has been allocated
    # to this station's drop- the user would allocate a pack count to a binfill station's
    # drop for exactly this purpose: allocating a fg product to a binfill station
    #------------------------------------------------------------------------------------
     if @@outlets && @@outlets[run_id] && self.has_attribute?("drop_code")
       self.pack_group = get_pack_group(run_id)
       
       if !match && self.pack_group
       
         self.color_percentage = self.pack_group.color_sort_percentage.to_s
         self.grade = self.pack_group.grade_code
         self.marketing_variety = self.pack_group.marketing_variety_code
       
       end
       if self.pack_group
         link = RebinLink.find_by_production_run_id_and_station_code(run_id,self.binfill_station_code)
         
         self.fg_product_code = link.fg_product_code if link
       end
      self.more_groups = self.additional_groups.length if self.additional_groups 
    end
    
  end
 
 def get_pack_group_old()
   
    query = "SELECT distinct public.pack_groups.id
             FROM
             public.pack_group_outlets
             INNER JOIN public.pack_groups ON (public.pack_group_outlets.pack_group_id = public.pack_groups.id)
             WHERE
            ((public.pack_group_outlets.outlet1 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet2 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet3 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet4 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet5 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet6 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet7 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet8 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet9 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet10 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet11 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet12 = '#{self.drop_code}')) AND
            (public.pack_group_outlets.standard_size_count_value is not null)AND
            (public.pack_groups.production_run_id = '#{@@production_run_id}')"
            
    group_id = PackGroup.find_by_sql(query).map{|i|i.id}[0]
    if group_id
     return PackGroup.find(group_id)
    else
      return nil
    end
    
   end
   
   
   def BinfillStation.set_cross_product_pack_groups_ids(run_id)
    if @@pack_id_outlets && @@pack_id_outlets[run_id]
     return
    end
    
    query = "SELECT distinct public.pack_groups.id,outlet1,outlet2,outlet3,outlet4,outlet5,outlet6,outlet7,outlet8,outlet9,outlet10,outlet11,outlet12
              FROM public.pack_group_outlets
              INNER JOIN public.pack_groups ON (public.pack_group_outlets.pack_group_id = public.pack_groups.id)
              WHERE
              (public.pack_group_outlets.standard_size_count_value is not null)AND
              (public.pack_groups.production_run_id = '#{run_id}')"
    
    @@pack_id_outlets = Hash.new if !@@pack_id_outlets
    @@pack_id_outlets[run_id] = self.connection.select_all(query)
   
   end
   
    
   def get_pack_group(run_id)
     #-------------------------------------------------------------------------------
     #Loop through list of pack group with outlets records and see if a record can be
     #matched with this station's drop code. If matched find the pack_group with
     #by it's id and return
     #--------------------------------------------------------------------------------
     pack_outlet = nil
     if @@pack_id_outlets && @@pack_id_outlets[run_id]
       pack_outlet = @@pack_id_outlets[run_id].find{|p|p['outlet1']== self.drop_code||p['outlet2']== self.drop_code||p['outlet3']== self.drop_code||p['outlet4']== self.drop_code||p['outlet5']== self.drop_code||p['outlet6']== self.drop_code||p['outlet7']== self.drop_code||p['outlet8']== self.drop_code||p['outlet9']== self.drop_code||p['outlet10']== self.drop_code||p['outlet11']== self.drop_code||p['outlet12']== self.drop_code}
     end
     if pack_outlet
      return PackGroup.find(pack_outlet["id"].to_i)
     else
      return nil
     end
    
   end
   
   
    def get_pack_group_old()
   
    query = "SELECT distinct public.pack_groups.id
             FROM
             public.pack_group_outlets
             INNER JOIN public.pack_groups ON (public.pack_group_outlets.pack_group_id = public.pack_groups.id)
             WHERE
            ((public.pack_group_outlets.outlet1 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet2 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet3 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet4 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet5 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet6 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet7 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet8 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet9 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet10 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet11 = '#{self.drop_code}') OR
            (public.pack_group_outlets.outlet12 = '#{self.drop_code}')) AND
            (public.pack_group_outlets.standard_size_count_value is not null)AND
            (public.pack_groups.production_run_id = '#{@@production_run_id}')"
            
    group_id = PackGroup.find_by_sql(query).map{|i|i.id}[0]
    if group_id
     return PackGroup.find(group_id)
    else
      return nil
    end
    
   end
 
 
 def BinfillStation.next_id(line_config_id)
  
   query = "SELECT max(binfill_stations.station_gen_code)as maxval
           FROM
           public.binfill_stations
           INNER JOIN public.drops ON (public.binfill_stations.drop_id = public.drops.id)
           INNER JOIN public.line_configs ON (public.drops.line_config_id = public.line_configs.id)
            where 
           (public.line_configs.id = '#{line_config_id}')"
           
   val = connection.select_one(query)
   if val["maxval"]== nil
     return 1
   else
    return val["maxval"].to_i + 1
   end
   
  end


end
