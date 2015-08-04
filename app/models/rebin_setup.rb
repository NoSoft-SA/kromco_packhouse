class RebinSetup < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
	has_one :rebin_label_setup,:dependent => :destroy
	has_one :rebin_template,:dependent => :destroy
	has_many :rebin_links, :dependent => :destroy
	
	belongs_to :production_schedule
	belongs_to :rmt_product
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :production_schedule_code
	
	validates_presence_of :product_code_pm_bintype
	#validates_presence_of :printer_format
	
#	=====================
#	 Complex validations:
#	=====================

  attr_reader :rmt_description,:rmt_code,:pc_code,:puc,:printer_format
  attr_writer :rmt_description,:rmt_code,:pc_code,:puc,:printer_format
  
  
  
  def validate 
#	first check whether combo fields have been selected

    self.label_code = 'BIN1'
    
     if !self.color_percentage
	   self.color_percentage = -1
	  end
	  
	  ModelHelper::Validations.validate_combos([{:product_code_pm_bintype => self.product_code_pm_bintype}],self) 
     
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:printer_format => self.printer_format}],self) 
#	 end
  end
  
  
  def RebinSetup.rmt_codes_for_station_link_context(binfill_station)
   
   
    results = RebinSetup.find_all_by_production_schedule_code_and_grade_code_and_color_percentage_and_variety_output_description_and_size(binfill_station.production_schedule_name,binfill_station.grade,binfill_station.color_percentage,binfill_station.marketing_variety,binfill_station.size)
    fin_results = nil
    if binfill_station.additional_groups 
      binfill_station.additional_groups.each do |group|
        results.concat(RebinSetup.find_all_by_production_schedule_code_and_grade_code_and_color_percentage_and_variety_output_description_and_size(binfill_station.production_schedule_name,group[1],group[0],binfill_station.marketing_variety,binfill_station.size))
      end
  
      #remove all duplicates
      distincts = Hash.new
      fin_results = Array.new
      results.each do |result|
      if !distincts.has_key?(result.id)
       distincts.store(result.id,result)
       fin_results.push(result)
      end
    end
  else
   fin_results = results
  end
  return fin_results
 end
  
  
  def RebinSetup.siblings_created_for_processing_setup?(processing_setup,schedule_id)
     query = " select id from rebin_setups where (production_schedule_id = '#{schedule_id}' and standard_size_count_from <= '#{processing_setup.standard_size_count_from}' and
	                        standard_size_count_to >= '#{processing_setup.standard_size_count_to}' and
	                        standard_size_count_to <= '#{processing_setup.standard_size_count_from}' and
	                        standard_size_count_from >= '#{processing_setup.standard_size_count_to}' and
	                        (auto_created = null or auto_created = false) and standard_size_count_from <> -1)"
  
   if RebinSetup.find_by_sql(query).length() == 0
    return false
   else
    return true
   end
  
  end
  
  def RebinSetup.next_sequence_for_grain(class_code,size_code,schedule_code)
     query = "SELECT max(rebin_setups.sequence_number)as maxval
           FROM
           public.rebin_setups where 
           (public.rebin_setups.production_schedule_code = '#{schedule_code}' AND
           rebin_setups.size = '#{size_code}')"
            
     val = connection.select_one(query)
     if val["maxval"]== nil
       return 1
     else
       return val["maxval"].to_i + 1
     end
  
  end
  
  
   def RebinSetup.re_sequence_group(schedule_code,class_code,size)
    self.transaction do
     grains = RebinSetup.find_all_by_production_schedule_code_and_product_class_code_and_size(schedule_code,class_code,size,:order => "sequence_number")
     new_sequence = 0
     grains.each do |grain|
         new_sequence += 1
         grain.sequence_number = new_sequence
         grain.update
     end
   end
  end
  #-----------------------------------------------------------------------
  #Find the appropriate rmt_product and set to rebin- if rmt_product does
  #not exist, create it
  #-----------------------------------------------------------------------
  def set_rmt_product
    RAILS_DEFAULT_LOGGER.info("NAE PROBLEM self.production_schedule_code " + self.production_schedule_code)
    rmt_setup = RmtSetup.find_by_production_schedule_name(self.production_schedule_code)

    if !rmt_setup
	        RAILS_DEFAULT_LOGGER.info("NAE PROBLEM !rmt_setup " )    
    end
    commodity = rmt_setup.commodity_code
    RAILS_DEFAULT_LOGGER.info("NAE PROBLEM rmt_setup.commodity_code " + rmt_setup.commodity_code)    
    
    rmt_product = RmtProduct.find_by_commodity_code_and_variety_code_and_treatment_code_and_ripe_point_code_and_product_class_code_and_size_code_and_bin_type(commodity,self.variety_output_description,self.treatment_code,self.ripe_point_code,self.product_class_code,self.size,self.product_code_pm_bintype)
    if !rmt_product
     
     rmt_product = RmtProduct.new
     rmt_product.commodity_code = commodity
     rmt_product.commodity_group_code = Commodity.find_by_commodity_code(commodity).commodity_group_code
     rmt_product.variety_code = variety_output_description
     rmt_product.treatment_code = self.treatment_code
     rmt_product.ripe_point_code = self.ripe_point_code
     rmt_product.bin_type = self.product_code_pm_bintype
     rmt_product.product_class_code = self.product_class_code
     rmt_product.size_code = self.size
     rmt_product.rmt_product_type_code = "rebin"
     if !rmt_product.save
       raise "rmt product creation failed. Errors are: " + rmt_product.errors.full_messages.to_s
     end
    end
    
    self.rmt_product = rmt_product
    self.rmt_product_code = rmt_product.rmt_product_code
    
    
  end
  
  
  def clone_setup(other_schedule = nil)
    rebin_setup = RebinSetup.new
    rebin_setup.rmt_product = self.rmt_product
    rebin_setup.rmt_product_code = self.rmt_product_code
    
    export_attributes(rebin_setup)
     if !other_schedule
      rebin_setup.production_schedule = self.production_schedule
    else
      rebin_setup.production_schedule = other_schedule
      rebin_setup.production_schedule_code = other_schedule.production_schedule_name
    end
    
    rebin_setup.auto_created = false
    #--------------------------------------------------------------------------------------
    #jan 09 changes: get ripe point code and track indicator code from schedule's rmt setup
    #--------------------------------------------------------------------------------------
    rebin_setup.ripe_point_code = other_schedule.ripe_point_code if other_schedule.ripe_point_code
    
    rebin_setup.create
    
    if self.rebin_label_setup
       rebin_label_setup = RebinLabelSetup.new
       self.rebin_label_setup.export_attributes(rebin_label_setup)
       rebin_label_setup.rebin_setup = rebin_setup
       rebin_label_setup.label = self.rebin_label_setup.label
       rebin_label_setup.pc_code = other_schedule.rmt_setup.pc_code
       rebin_label_setup.create
    end
  
    rebin_setup.create_rebin_template
    rebin_setup.rebin_template.farm_group_code = other_schedule.farm_group_code if other_schedule
    rebin_setup.rebin_template.update  if other_schedule
    
  end
  
  #----------------------------------------------------------------------------------
  #the passed-in array holds the size counts
  #the inner arrays holds the from and to range values (positions 0 and 1 respectively)
  #we need to 1) edit the original value with the range values of the first item and
  #2) create a new rebin setup record for each new range- in doing this we must copy
  #   all the values from rebin setup(original record) to the new records
  #----------------------------------------------------------------------------------
  def split_size_counts(sub_ranges)
    self.transaction do
      #update the ranges of the current record
      self.standard_size_count_from = sub_ranges[0][0]
      self.standard_size_count_to = sub_ranges[0][1]
      self.update
      #create a new rebin record for each item from 1 onwards and copy
      #the attribues from this record to each new record
      for i in 1..sub_ranges.length()-1
        rebin_setup = RebinSetup.new
        rebin_setup.production_schedule = self.production_schedule
        export_attributes(rebin_setup)
       
        rebin_setup.standard_size_count_from = sub_ranges[i][0]
        rebin_setup.standard_size_count_to = sub_ranges[i][1]
        rebin_setup.auto_created = false
        rebin_setup.create
        if self.rebin_label_setup
          rebin_label_setup = RebinLabelSetup.new
          self.rebin_label_setup.export_attributes(rebin_label_setup)
          rebin_label_setup.rebin_setup = rebin_setup
          rebin_label_setup.label = self.rebin_label_setup.label
          rebin_label_setup.create
        end
        
        
      end
   
  
    end
  
  end
  
  def before_create
  
   set_rmt_product
   
   if self.production_schedule.production_schedule_status_code == "re_opened"
    #PackGroup.re_sync_with_rebin(self,self.production_schedule_code)
   end
   
   self.sequence_number = RebinSetup.next_sequence_for_grain(self.product_class_code,self.size,self.production_schedule.production_schedule_name)
   
  end
  #-------------------------------------------------------------------------------
  #Attributes mapped to rebin_label_setups will be written to it
  #just before rebin_setup is updated
  #The reverse mapping takes place on after_find
  #-------------------------------------------------------------------------------
  
  def before_update
    
    #determine if size or class has changed, if so re-sequence old size-class group and set this record's
    #sequence as next val of the new size-class group to which this record now belongs to
    old_record_state = RebinSetup.find(self.id)
    if old_record_state.product_class_code != self.product_class_code ||old_record_state.size != self.size
      self.sequence_number = RebinSetup.next_sequence_for_grain(self.product_class_code,self.size,self.production_schedule.production_schedule_name)
      RebinSetup.re_sequence_group(self.production_schedule.production_schedule_name,self.product_class_code, self.size)
    end
    
   
    set_rmt_product
    
    rebin_label_setup = nil
    if self.rebin_label_setup == nil
      rebin_label_setup = RebinLabelSetup.new
    else
      rebin_label_setup = self.rebin_label_setup
    end
    
    if self.label_code != nil #this is to bypass a cascading update from procc setup
     puts "creating label setup"
      rebin_label_setup.rmt_description = TrackIndicator.find_by_track_indicator_code(self.production_schedule.rmt_setup.track_indicator_code).description
      #-------------------------------------------------------------------------
      #Jan 09 changes: use track indicato code, not output track indicator code
      #-------------------------------------------------------------------------
      rebin_label_setup.rmt_code = self.production_schedule.rmt_setup.track_indicator_code
      rebin_label_setup.class_code = self.rmt_product.product_class.product_class_description
      rebin_label_setup.size_code = self.size
      rebin_label_setup.pc_code = self.production_schedule.rmt_setup.pc_code
      
      rebin_label_setup.label_code = self.label_code
      rebin_label_setup.commodity_code = self.commodity_code
      rebin_label_setup.rebin_setup = self
      rebin_label_setup.label = Label.find_by_label_code(self.label_code)
      rebin_label_setup.label_type = rebin_label_setup.label.label_type.label_type_code
      #rebin_label_setup.printer_format_code = self.printer_format
    
     #----------------------------------------------
     #TO BE ADDED AT RUNTIME
     #-> farm_code (of production run)
     #-> weight (runtime)
     #-> transaction date
     #-> operator name (who took the weight)
     #-> line number (of the run)
     #-> bin id 
     #-----------------------------------------------
     
      if !rebin_label_setup.save
       raise "rebin label setup could not be saved. Errors(s): " + rebin_label_setup.errors.full_messages.to_s
      end
      
      self.rebin_label_setup = rebin_label_setup
      create_rebin_template
      
    end
    
   
   
  end
  
  def after_destroy
    RebinSetup.re_sequence_group(self.production_schedule.production_schedule_name,self.product_class_code, self.size)
  
  end
  
  
  def create_rebin_template
    rebin_template = nil
    if self.rebin_template == nil
      rebin_template = RebinTemplate.new
    else
      rebin_template = self.rebin_template
    end
   
    rebin_template.production_schedule_code = self.production_schedule.production_schedule_name
    rebin_template.class_code = self.product_class_code
    rebin_template.product_code_pm_bintype =self.product_code_pm_bintype
    rebin_template.size_code = self.size
    rebin_template.farm_group_code = self.production_schedule.farm_group_code
    rmt_setup = RmtSetup.find_by_production_schedule_name(self.production_schedule_code)
    commodity = rmt_setup.commodity_code
    rebin_template.commodity_code = commodity 
    rebin_template.marketing_variety_code = self.variety_output_description
    rebin_template.ripe_point_code = self.ripe_point_code
    rebin_template.rmt_product_code = self.rmt_product_code 
    rebin_template.product_code_pm_bintype = self.product_code_pm_bintype
    rebin_template.cold_store_code = rmt_setup.cold_store_code
    rebin_template.treatment_type_code = self.treatment_type_code
    rebin_template.season_code = self.production_schedule.season_code
    bin_pm = PackMaterialProduct.find_by_pack_material_product_code(self.product_code_pm_bintype)
    raise "No bin pack material selected for this rebin setup(" + self.is.to_s + ")" if !bin_pm
    bin_weight = 0
    bin_weight = bin_pm.material_mass.to_i if bin_pm.material_mass
    raise "No material mass defined for bin type: " + bin_pm.pack_material_product_code if bin_weight == 0
    rebin_template.bin_weight = bin_weight
    rebin_template.pc_code = self.production_schedule.rmt_setup.pc_code
    rebin_template.treatment_code = self.treatment_code #which was obtained from treatment code on rmt_setup of schedule
    #-------------------------------------------------------------------------------------------------------
    #Jan 09 change: track_indicator_code comes from track_indicator on rmt_setup, not output track indicator
    #-------------------------------------------------------------------------------------------------------
    rebin_template.track_indicator_code = rmt_setup.track_indicator_code
    
    rebin_template.rebin_setup = self
    
    #-----------------------------------------------------------------------------------------
    #TO BE ADDED AT RUNTIME
    #-> production run code (schedule + run number)
    #-> farm_code (runtime- belonging to production run)
    #-> bin_type (at runtime)
    #-> current iso_week (of current date_time) 
    #-> orchard_id (concat string farm_code '_' + input_variety
    #-----------------------------------------------------------------------------------------
    rebin_template.save
    self.rebin_template = rebin_template
  
  end
  
   
  def before_destroy
  
    self.rebin_label_setup.destroy if  self.rebin_label_setup
  
  end
  
  def after_find
    if self.rebin_label_setup != nil
      self.rmt_description = self.rebin_label_setup.rmt_description
      self.pc_code = self.rebin_label_setup.pc_code
      self.puc = self.rebin_label_setup.puc
      self.printer_format = self.rebin_label_setup.printer_format_code
      self.rmt_code = self.rebin_label_setup.rmt_code
      #self.label_code = self.rebin_label_setup.label_code
      
    end
  
  
  end
  

end
