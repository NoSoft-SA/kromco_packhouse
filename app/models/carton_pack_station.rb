class CartonPackStation < ActiveRecord::Base
  
  
  @@outlets = nil
  @@carton_links = nil
  #@@production_run_id = nil
  @@pack_id_outlets = nil
  
  belongs_to :table
  validates_presence_of :station_code
  validates_associated :table
  
  
  attr_accessor :size_count,:color_percentage,:grade,:marketing_variety,
                :drop_code,:table_code,:fg_product_code,
                :production_schedule_name,:production_run_number,:carton_setup_code,
                :additional_groups,:more_groups,:rebin_group,:rmt_product_code,:extended_fg_code,
                :inventory_code,:target_market,:marking,:diameter,:nett_mass,:order_no,:packing_order,
                :retailer_sell_by_code,:palletizing
  
  
  #---------------------------------------------------------------------------------------
  #This static method is used to set outlets for the run- outlets(associated
  #with pack_groups)Each outlet record contains fields outlets1 to 6, the values 
  #of which contain drop codes. So, an instance of carton_pack_station can search
  #for the outlet records for a drop match in one of the outlet fields. Once that is
  #found, it can obtain the pack_group associated info: color_sort%,grade_code,size_count
  #standard_size_count_value
  #----------------------------------------------------------------------------------------
  def validate
  
  
  end
  
#  def production_run_id
#   @@production_run_id
#   
#  end
  
 
  def CartonPackStation.exists_for_line_config(config_id,station_code)
  
   query = "SELECT carton_pack_stations.station_code
           FROM
           public.tables
           INNER JOIN public.drops ON (public.tables.drop_id = public.drops.id)
           INNER JOIN public.line_configs ON (public.drops.line_config_id = public.line_configs.id)
           INNER JOIN public.carton_pack_stations ON (public.tables.id = public.carton_pack_stations.table_id)
           WHERE
           (public.line_configs.id = '#{config_id}') AND 
           (public.carton_pack_stations.station_code = '#{station_code}')"
  
   return CartonPackStation.find_by_sql(query)[0]
  
  end
   
  def CartonPackStation.clear_product_allocation_data(run_id)
   @@outlets.delete(run_id) if @@outlets
   @@carton_links.delete(run_id) if @@carton_links
   @@pack_id_outlets.delete(run_id) if @@pack_id_outlets
 end
  
  def CartonPackStation.set_outlets(outlets,run_id)
    @@outlets = Hash.new if !@@outlets
    @@outlets[run_id] = outlets
    CartonPackStation.set_cross_product_pack_groups_ids(run_id)
    
  end
  
   def CartonPackStation.set_cross_product_pack_groups_ids(run_id)
    if @@pack_id_outlets && @@pack_id_outlets[run_id]
     return
    end
    
    query = "SELECT distinct public.pack_groups.id,outlet1,outlet2,outlet3,outlet4,outlet5,outlet6,outlet7,outlet8,outlet9,outlet10,outlet11,outlet12,public.pack_group_outlets.id as outlet_id
              FROM public.pack_group_outlets
              INNER JOIN public.pack_groups ON (public.pack_group_outlets.pack_group_id = public.pack_groups.id)
              WHERE
              (public.pack_group_outlets.size_code is not null)AND
              (public.pack_groups.production_run_id = '#{run_id}')"
    
    @@pack_id_outlets = Hash.new if !@@pack_id_outlets          
    @@pack_id_outlets[run_id] = self.connection.select_all(query)
   
   end
  
  
   def CartonPackStation.get_outlets(run_id)
    if @@outlets
     return @@outlets[run_id] 
    else
      return nil
    end
  end
  
  def CartonPackStation.set_carton_links(links,run_id)
    @@carton_links = Hash.new if !@@carton_links
    @@carton_links[run_id] = links
  end
  
#  def CartonPackStation.set_production_run_id(run_id)
#  
#    @@production_run_id = run_id
#  
#  end
  
  def set_product_context(run_id)
  
    if self.has_attribute?("table_code")
      self.table_code = self.attributes["table_code"]
      
    end
    
    if self.has_attribute?("drop_code")
      self.drop_code = self.attributes["drop_code"]
    end
    
    
   if self.has_attribute?("line_code")
     line_code = self.attributes["line_code"].gsub("line","")
     self.station_code = self.station_code.gsub("x",line_code) 
   end
   
   #--------------------------------------------------------------------------------------------------------------------
   #Populate fields size_count,grade,marketing_variety
   #if a matching outlet_record can be found- outlets alraedy filtered for the line belonging to current production run 
   #--------------------------------------------------------------------------------------------------------------------
  
    if @@outlets && @@outlets[run_id] && self.has_attribute?("drop_code")
     
      match = @@outlets[run_id].find{|r|r.outlet1 == self.drop_code ||r.outlet2 == self.drop_code ||r.outlet3 == self.drop_code ||r.outlet4 == self.drop_code||r.outlet5 == self.drop_code ||r.outlet6 == self.drop_code||r.outlet7 == self.drop_code||r.outlet8 == self.drop_code||r.outlet9 == self.drop_code||r.outlet10 == self.drop_code||r.outlet11 == self.drop_code||r.outlet12 == self.drop_code}
      if match 
        
        self.color_percentage = match.pack_group.color_sort_percentage.to_s
        self.grade = match.pack_group.grade_code
        self.size_count = match.standard_size_count_value
        self.marketing_variety = match.pack_group.marketing_variety_code
        #----------------------------------------------------------------------------------------
        #ADDITIONAL GROUPS SCENARIO:
        #try to find other outlets that match this stations's drop code- this is possible, since 
        #a user can allocate a given drop to a given count from more than one group context, BUT
        #for the same count
        #----------------------------------------------------------------------------------------

        
        @@outlets[run_id].each do |outlet|
          if outlet.outlet1 == self.drop_code ||outlet.outlet2 == self.drop_code ||outlet.outlet3 == self.drop_code ||outlet.outlet4 == self.drop_code||outlet.outlet5 == self.drop_code ||outlet.outlet6 == self.drop_code||outlet.outlet7 == self.drop_code||outlet.outlet8 == self.drop_code||outlet.outlet9 == self.drop_code||outlet.outlet10 == self.drop_code||outlet.outlet11 == self.drop_code||outlet.outlet12 == self.drop_code
            if outlet.pack_group.color_sort_percentage.to_s != self.color_percentage.to_s || outlet.pack_group.grade_code.to_s != self.grade.to_s
              self.additional_groups = Array.new if !self.additional_groups
               self.additional_groups.push [outlet.pack_group.color_sort_percentage,outlet.pack_group.grade_code]
            end
          end
        end
        
        
        #now see if we have an fg match
        if @@carton_links && @@carton_links[run_id]
          link = @@carton_links[run_id].find{|f|f.production_run_id == match.production_run_id && f.station_code == self.station_code}
          self.fg_product_code = link.fg_product_code if link
          self.carton_setup_code = link.carton_setup_code if link
          if link 
            
          end
        end
          
      end
      
    end
    
    #------------------------------------------------------------------------------------
    #FOR CROSS PRODUCT ALLOCATION: i.e. allocating a rmt product to a pack station
    # Get the first pack group from within which a 'size' count has been allocated
    # to this station's drop- the user would allocate a rebin 'size' to a pack station's
    # drop for exactly this purpose: allocating a rmt product to a pack station
    #------------------------------------------------------------------------------------
     if @@outlets && @@outlets[run_id] && self.has_attribute?("drop_code")
       self.rebin_group = get_rebin_group(run_id)
       if !match && self.rebin_group
          self.color_percentage = self.rebin_group.color_sort_percentage.to_s
          self.grade = self.rebin_group.grade_code
          self.marketing_variety = self.rebin_group.marketing_variety_code
       end
       if self.rebin_group
         link = CartonLink.find_by_production_run_id_and_station_code(run_id,self.station_code)
         self.rmt_product_code = link.rmt_product_code if link
       end
      self.more_groups = self.additional_groups.length if self.additional_groups 
    end
  end
  
  
    def get_rebin_group(run_id)
     #-------------------------------------------------------------------------------
     #Loop through list of pack group with outlets records and see if a record can be
     #matched with this station's drop code. If matched find the pack_group with
     #by it's id and return
     #--------------------------------------------------------------------------------
     return if !self.drop_code
     puts self.drop_code
     
     if @@pack_id_outlets
      p = @@pack_id_outlets[run_id].find{|p|p['outlet1']== self.drop_code||p['outlet2']== self.drop_code||p['outlet3']== self.drop_code||p['outlet4']== self.drop_code||p['outlet5']== self.drop_code||p['outlet6']== self.drop_code||p['outlet7']== self.drop_code||p['outlet8']== self.drop_code||p['outlet9']== self.drop_code||p['outlet10']== self.drop_code||p['outlet11']== self.drop_code||p['outlet12']== self.drop_code}
     end
     
     if p
      return PackGroup.find(p["id"].to_i)
     else
      return nil
     end
    
   end
  
 
  
   #--------------------------------------------------------------------
   # Serving cross-product allocation 
   #--------------------------------------------------------------------
   
   def get_rebin_group_old()
   
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
            (public.pack_group_outlets.size_code is not null)AND
            (public.pack_groups.production_run_id = '#{@@production_run_id}')"
            
    group_id = PackGroup.find_by_sql(query).map{|i|i.id}[0]
    if group_id
     return PackGroup.find(group_id)
    else
      return nil
    end
    
   end
   
   
   
  
  
  def CartonPackStation.count_stations_for_line_and_side(line_id,side)
  
  query = "SELECT count(*) AS count_all FROM
          (SELECT public.carton_pack_stations.station_code FROM public.lines
           INNER JOIN public.line_configs ON (public.lines.line_config_id =
           public.line_configs.id) INNER JOIN public.drops ON
          (public.line_configs.id = public.drops.line_config_id)
           INNER JOIN public.tables ON (public.drops.id = public.tables.drop_id)
           INNER JOIN public.carton_pack_stations ON
          (public.tables.id = public.carton_pack_stations.table_id) WHERE
          (public.lines.id = '#{line_id}')) as foo"
  
          val = connection.select_one(query)
          return val["count_all"]
   
  
  end
  
  def CartonPackStation.is_alpha_numeric
    return true
 
   end
  
  def CartonPackStation.next_id(table_id)
  
   query = "SELECT max(carton_pack_stations.station_gen_code)as maxval
           FROM
           public.carton_pack_stations where 
           (carton_pack_stations.table_id = '#{table_id}')"
           
   val = connection.select_one(query)
   if val["maxval"]== nil
     return 1
   else
    return val["maxval"].to_i + 1
   end
   
  end
  
end
