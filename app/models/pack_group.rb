class PackGroup < ActiveRecord::Base
    
  belongs_to :production_run
  has_many :pack_group_outlets,:dependent => :destroy,:order => "id"
  
  @@ignore_after_find = Hash.new
  #-----------------------------------------------------------------
  #The context of a call to this method is a production_schedule put
  #in a 're-opened' state and a run put in a 're_configuring' state
  #These states allow a user to typically do the following:
  #1) Create  new rebin record(s)
  #2) Create new carton setup record(s)
  #We need to make sure that for such new additions, we have
  #1) sufficient pack groups (we may have to create a new one)
  #2) 'outlet_records' set correctly: i.e. during the
  #   initial creation of the outlets for a pack group, a given
  #   outlet may have been set to 'n.a.' because a matching carton
  #   setup or rebin setup for the relevant count could not be found
  #   The new addition of a rebin or carton setup can however invalidate
  #   the initial setting, in which case, we need to clear the 'n.a' for
  #   the relevant outlet for the count of the new addition
  #----------------------------------------------------------------- 
  def PackGroup.re_sync_with_rebin(rebin_setup,schedule_code)
    #first find all runs for this schedule that is in a 'reconfiguring' state
    runs = ProductionRun.find_all_by_production_schedule_name_and_production_run_status(schedule_code,"reconfiguring")
    if runs
    runs.each do |run|
      #try to find a pack group match
      pack_group = PackGroup.find_by_production_run_id_and_color_sort_percentage_and_grade_code(run.id,rebin_setup.color_percentage,rebin_setup.grade_code)
      if pack_group
        #find the outlet for the group where the size value matches
        outlet = PackGroupOutlet.find_by_pack_group_id_and_size_code(pack_group.id,rebin_setup.size)
        PackGroup.clear_outlets(outlet)
        outlet.update
      
      else
        #create new pack_group
        pack_group = PackGroup.new
        group_number = PackGroup.next_group_number(run.id)
                       
        pack_group.pack_group_number = group_number
        pack_group.commodity_code = rebin_setup.rmt_product.commodity_code
        pack_group.marketing_variety_code = rebin_setup.variety_output_description
        pack_group.color_sort_percentage = rebin_setup.color_percentage
        pack_group.grade_code = rebin_setup.grade_code
        pack_group.production_run_number = run.production_run_number
        pack_group.production_schedule_name = schedule_code
        pack_group.production_run = run
        pack_group.create
        #At this point outlet records have not been defined: this is OK, since the first 'find'
        #called on the pack group will build the outlets on demand (opn 'after_find')
      end
    
    end
  end
  
  end
  
  def save_to_sizer_template(template_group)
    #------------------------------------------------------------------------------------------
    #by virtue of being here, we can assume that outlets have been created for
    #this packgroup. We need to list the two outlet groups next to each other and
    #for each item, overwrite the template's group values with that of this pack group
    #------------------------------------------------------------------------------------------
    begin
    need_update = false
    #puts "template group: " + template_group.color_sort_percentage.to_s
    puts "n outlets: " + self.pack_group_outlets.length().to_s
    for i in 0..self.pack_group_outlets.length() -1
       need_update = false
       puts "in group"
      outlet = self.pack_group_outlets[i]
      condition =""
      if outlet.standard_size_count_value
        condition = "standard_size_count_value = '#{outlet.standard_size_count_value}'"
      else
        condition = "size_code = '#{outlet.size_code}'"
      end
      
      template_outlet = template_group.pack_group_template_outlets.find(:first,:conditions => condition)
      if outlet.standard_size_count_value != template_outlet.standard_size_count_value ||outlet.size_code != template_outlet.size_code
        raise "Outlet and template outlet comparison mismatch- the counts are not the same!"
      end
      
      if outlet.outlet1 != nil
        template_outlet.outlet1 = outlet.outlet1 
        need_update = true
      end
      
      if outlet.outlet2 != nil
        template_outlet.outlet2 = outlet.outlet2
        need_update = true
      end
      
      if outlet.outlet3 != nil
        template_outlet.outlet3 = outlet.outlet3
        need_update = true
      end
      
      if outlet.outlet4 != nil
        template_outlet.outlet4 = outlet.outlet4 
        need_update = true
      end
      
      if outlet.outlet5 != nil
        template_outlet.outlet5 = outlet.outlet5
        need_update = true
      end
      
      if outlet.outlet6 != nil
        template_outlet.outlet6 = outlet.outlet6
        need_update = true
      end
      
       if outlet.outlet7 != nil
        template_outlet.outlet7 = outlet.outlet7
        need_update = true
      end
      
       if outlet.outlet8 != nil
        template_outlet.outlet8 = outlet.outlet8
        need_update = true
      end
      
       if outlet.outlet9 != nil
        template_outlet.outlet9 = outlet.outlet9
        need_update = true
      end
      
       if outlet.outlet10 != nil
        template_outlet.outlet10 = outlet.outlet10
        need_update = true
      end
      
       if outlet.outlet11 != nil
        template_outlet.outlet11 = outlet.outlet11
        need_update = true
      end
      
       if outlet.outlet12 != nil
        template_outlet.outlet12 = outlet.outlet12
        need_update = true
      end
      
      template_outlet.update if need_update == true
      puts "sizer template group saved: " + need_update.to_s
     end
    rescue
     raise $!
    end
  end

  def apply_sizer_template(template_group)
    #------------------------------------------------------------------------------------------
    #by virtue of being here, we can assume that outlets have been created for
    #this packgroup. We need to list the two outlet groups next to each other and
    #for each item, see whether the pack_group's outlet record has a gap- meaning a null value
    # if so, and if the template outlet has a value we need to copy the value and save the 
    # pack group outlet record
    #------------------------------------------------------------------------------------------
    begin
    need_update = false
    #puts "template group: " + template_group.color_sort_percentage.to_s
    puts "n outlets: " + self.pack_group_outlets.length().to_s
    for i in 0..self.pack_group_outlets.length() -1
       need_update = false
       puts "in group"
      outlet = self.pack_group_outlets[i]
      condition =""
      if outlet.standard_size_count_value
        condition = "standard_size_count_value = '#{outlet.standard_size_count_value}'"
      else
        condition = "size_code = '#{outlet.size_code}'"
      end
      
      template_outlet = template_group.pack_group_template_outlets.find(:first,:conditions => condition)
      if template_outlet
        if outlet.standard_size_count_value != template_outlet.standard_size_count_value ||outlet.size_code != template_outlet.size_code
          raise "Outlet and template outlet comparison mismatch- the counts are not the same!"
        end
      
        if outlet.outlet1 == nil && template_outlet.outlet1 != nil
          outlet.outlet1 = template_outlet.outlet1
          need_update = true
        end
      
        if outlet.outlet2 == nil && template_outlet.outlet2 != nil
          outlet.outlet2 = template_outlet.outlet2
          need_update = true
        end
      
        if outlet.outlet2 == nil && template_outlet.outlet2 != nil
          outlet.outlet2 = template_outlet.outlet2
          need_update = true
        end
      
        if outlet.outlet3 == nil && template_outlet.outlet3 != nil
          outlet.outlet3 = template_outlet.outlet3
          need_update = true
        end
      
        if outlet.outlet4 == nil && template_outlet.outlet4 != nil
          outlet.outlet4 = template_outlet.outlet4
          need_update = true
        end
      
        if outlet.outlet5 == nil && template_outlet.outlet5 != nil
          outlet.outlet5 = template_outlet.outlet5
          need_update = true
        end
      
        if outlet.outlet6 == nil && template_outlet.outlet6 != nil
          outlet.outlet6 = template_outlet.outlet6
          need_update = true
        end
      
        if outlet.outlet7 == nil && template_outlet.outlet7 != nil
          outlet.outlet7 = template_outlet.outlet7
          need_update = true
        end
      
        if outlet.outlet8 == nil && template_outlet.outlet8 != nil
          outlet.outlet8 = template_outlet.outlet8
          need_update = true
        end
      
        if outlet.outlet9 == nil && template_outlet.outlet9 != nil
          outlet.outlet9 = template_outlet.outlet9
          need_update = true
        end
      
        if outlet.outlet10 == nil && template_outlet.outlet10 != nil
          outlet.outlet10 = template_outlet.outlet10
          need_update = true
        end
      
        if outlet.outlet11 == nil && template_outlet.outlet11 != nil
          outlet.outlet11 = template_outlet.outlet11
          need_update = true
        end
      
        if outlet.outlet12 == nil && template_outlet.outlet12 != nil
          outlet.outlet12 = template_outlet.outlet12
          need_update = true
        end
      
        outlet.update if need_update == true
        puts "sizer applied to group: " + need_update.to_s
      end
     end
    rescue
     raise $!
    end
  end
  

  def PackGroup.re_sync_with_carton(carton_setup,schedule_code)
    #first find all runs for this schedule that is in a 'reconfiguring' state
    runs = ProductionRun.find_all_by_production_schedule_name_and_production_run_status(schedule_code,"reconfiguring")
    runs.each do |run|
      #try to find a pack group match
      pack_group = PackGroup.find_by_production_run_id_and_color_sort_percentage_and_grade_code(run.id,carton_setup.color_percentage,carton_setup.grade_code)
      if pack_group
        #find the outlet for the group where the size value matches
        outlet = PackGroupOutlet.find_by_pack_group_id_and_standard_size_count_value(pack_group.id,carton_setup.standard_size_count_value)
        PackGroup.clear_outlets(outlet)
        outlet.update
      
      else
        #create new pack_group
        pack_group = PackGroup.new
        group_number = PackGroup.next_group_number(run.id)
                       
        pack_group.pack_group_number = group_number
        pack_group.pack_group_number = group_number
        pack_group.commodity_code = carton_setup.retail_item_setup.item_pack_product.commodity_code
        pack_group.marketing_variety_code = carton_setup.marketing_variety_code
        pack_group.color_sort_percentage = carton_setup.color_percentage
        pack_group.grade_code = carton_setup.grade_code
        pack_group.production_run_number = run.production_run_number
        pack_group.production_schedule_name = schedule_code
        pack_group.production_run = run
        pack_group.create
        #At this point outlet records have not been defined: this is OK, since the first 'find'
        #called on the pack group will build the outlets on demand (opn 'after_find')
      end
    
    end
  
  
  end
 
 #------------------------------------------------------------------------------------------
 #IF THIS RECORD HAS NO 'PACK_GROUP_OUTLET' RECORDS BELONGING TO IT:
 #  1)Use the pack_group_counts_config table to get a list (in order- order by id)
 #    of all counts(to be used by all groups)for the commodity
 #  2)Create a set of pack_group outlet records- one per count found in 2
 #  3)for each outlet record:
 #    Use the standard count or size attribute of the outlet record and,using the
 #    color percentage and grade values of this pack_group query the carton_setups
 #    or rebin_setups table (depending on whether a size or size_count value is active)
 #    to see whether such a count exist in the table (that is for the schedule,color perc,
 #    grade and standard size count combination)IF a matching record can not be found, set 
 #    the values of all outlet fields to 'n.a.'
 #------------------------------------------------------------------------------------------
  
  def PackGroup.set_ignore_after_find_on(run_id)
   @@ignore_after_find[run_id.to_s] = true
  end
  
  def PackGroup.set_ignore_after_find_off(run_id)
    @@ignore_after_find[run_id.to_s] = false
  end
  
  def PackGroup.ignore_after_find(run_id)
   if !@@ignore_after_find[run_id.to_s]
     @@ignore_after_find[run_id.to_s] = false
   end
   
   @@ignore_after_find[run_id.to_s]
   
  end
  
  def after_find
   return if PackGroup.ignore_after_find(self.production_run.id)
   
    puts "after find"
    if self.pack_group_outlets.length == 0
      counts = PackGroupsCountsConfig.find_all_by_commodity_code(self.commodity_code,:order => 'position')
      if counts.length == 0
        raise "No sequence of counts('pack_groups_counts_configs' table) have been defined for commodity '#{self.commodity_code}'.
               <br> Use the program called 'pack_groups_counts_configs'(usually under 'tools') to define the list(and order of) size_counts
               <br>to use for allocating drops to counts per pack_group"
      end
      
      counts.each do |count|
        pgo = PackGroupOutlet.new
        pgo.pack_group = self
        pgo.production_run = self.production_run
        if count.size_code
          pgo.size_code = count.size_code
        else
          pgo.standard_size_count_value = count.standard_size_count_value
        end
        #---------------------------------------------------------------------------------------------------------
        #now see whether such a count have been defined for the color percentage,grade and size_count combination
        #(for either rebin or carton_setup)
        #---------------------------------------------------------------------------------------------------------
        if count.size_code
#            if RebinSetup.find_all_by_production_schedule_code_and_grade_code_and_color_percentage_and_size(self.production_schedule_name,self.grade_code,self.color_sort_percentage,count.size_code).length == 0
#              set_outlets_to_na(pgo)
#            end
        else
            if CartonSetup.find_all_by_production_schedule_code_and_grade_code_and_color_percentage_and_standard_size_count_value(self.production_schedule_name,self.grade_code,self.color_sort_percentage,count.standard_size_count_value).length == 0
              set_outlets_to_na(pgo)
            end
        end
        pgo.create
      end
    
    end
  
  end
  
  def PackGroup.next_group_number(run_id)
  
    query = "SELECT max(pack_groups.pack_group_number)as maxval
           FROM
           public.pack_groups where 
           (pack_groups.production_run_id = '#{run_id}')"
           
   val = connection.select_one(query)
   if val["maxval"]== nil
     return 1
   else
    return val["maxval"].to_i + 1
   end
 end
 
  
  def PackGroup.clear_outlets(outlets_record)
    outlets_record.outlet1 = nil
    outlets_record.outlet2 = nil
    outlets_record.outlet3 = nil
    outlets_record.outlet4 = nil
    outlets_record.outlet5 = nil
    outlets_record.outlet6 = nil
    outlets_record.outlet7 = nil
    outlets_record.outlet8 = nil
    outlets_record.outlet9 = nil
    outlets_record.outlet10 = nil
    outlets_record.outlet11 = nil
    outlets_record.outlet12 = nil
  
  end
  
  def set_outlets_to_na(outlets_record)
    outlets_record.outlet1 = "n.a"
    outlets_record.outlet2 = "n.a"
    outlets_record.outlet3 = "n.a"
    outlets_record.outlet4 = "n.a"
    outlets_record.outlet5 = "n.a"
    outlets_record.outlet6 = "n.a"
    outlets_record.outlet7 = "n.a"
    outlets_record.outlet8 = "n.a"
    outlets_record.outlet9 = "n.a"
    outlets_record.outlet10 = "n.a"
    outlets_record.outlet11 = "n.a"
    outlets_record.outlet12 = "n.a"
  
  end
  
  
  
end
