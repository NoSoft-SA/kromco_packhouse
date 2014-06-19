class CartonSetup < ActiveRecord::Base

  belongs_to :production_schedule
  
  has_one :retail_item_setup,:dependent => :destroy
  has_one :retail_unit_setup,:dependent => :destroy
  has_one :trade_unit_setup,:dependent => :destroy
  has_one :fg_setup,:dependent => :destroy
  has_one :pallet_setup,:dependent => :destroy
  has_one :carton_template,:dependent => :destroy
  has_one :carton_label_setup, :dependent => :destroy
  has_one :pallet_label_setup, :dependent => :destroy
  has_one :pallet_template, :dependent => :destroy
  has_one :pallet_label_setup, :dependent => :destroy
  has_one :palletizing_criterium,:dependent => :destroy
  has_one :carton_setup_update_timestamp
  
  has_many :carton_links,:dependent => :destroy
  
    
  attr_accessor :vr_all_remarks,:vr_extended_fg_code,:vr_tm,:vr_inv,:vr_old_fg,:vr_marking,:vr_dia,:vr_palletizing,
                 :qty_required, :qty_produced


  def CartonSetup.set_carton_setups_activation(selected_carton_setups,active_state_before_selection)
  self.transaction do
    selected_ids=Array.new
    active_state_after_selection=Hash.new
    for carton in selected_carton_setups
        if carton.active != true
         selected_ids << "id=" + carton.id.to_s + " "
        end
        active_state_after_selection[carton.id]=carton.active
    end

    deselected=Array.new
    for rec in  active_state_before_selection
      if rec[1]==true
        if !active_state_after_selection.has_key?(rec[0])
           deselected << "id=" + rec[0].to_s + " "
        end
      end
    end

    if deselected.length > 0
      deselected_join = deselected.join(" OR ")
      deselected_query = "UPDATE carton_setups SET active=false where #{deselected_join}"
      self.connection.execute(deselected_query)
    end
    if selected_ids.length > 0
      selected_ids_join=selected_ids.join(" OR ")
      selected_query ="UPDATE carton_setups SET active=true where #{selected_ids_join}"
      self.connection.execute(selected_query)
    end
  end

  end
  
  def c_test
   1
  end
  
  def after_find
  
    pallet_remarks = ""
    pallet_remarks = self.pallet_setup.remarks if self.pallet_setup && self.pallet_setup.remarks
    
    tu_remarks = ""
    tu_remarks = self.trade_unit_setup.remarks if self.trade_unit_setup && self.trade_unit_setup.remarks
    
    fg_remarks = ""
    fg_remarks = self.fg_setup.remarks if self.fg_setup && self.fg_setup.remarks
    
    self.vr_all_remarks = tu_remarks + " " + pallet_remarks + " " + fg_remarks
    
    
     self.vr_extended_fg_code = self.fg_setup.extended_fg_code if self.fg_setup
     self.vr_tm = self.fg_setup.target_market if self.fg_setup 
     self.vr_inv = self.fg_setup.inventory_code if self.fg_setup 
     self.vr_old_fg = self.fg_setup.fg_code_old if self.fg_setup 
     self.vr_marking = self.fg_setup.marking if self.fg_setup
     
     self.vr_dia = self.fg_setup.diameter if self.fg_setup
     self.vr_palletizing = self.pallet_setup.palletizing if self.pallet_setup
     schedule = self.production_schedule_code
     
     season_code_vals = schedule.split("_")
     season_code = season_code_vals[0] + "_" + season_code_vals[1]
     
     if self.order_number && self.order_number.upcase != "N.A."
       season_order_quantity = SeasonOrderQuantity.find_by_season_code_and_customer_order_number(season_code,self.order_number)
       
       if season_order_quantity 
         self.qty_required = season_order_quantity.quantity_required
         self.qty_produced = season_order_quantity.quantity_produced
       end
     end
     
     
    
  end
  
  
  def validate
  
  
    
  
    self.color_percentage = -1 if ! self.color_percentage
    self.order_number = "n.a." if ! self.order_number
    
    if self.trade_env_code
      trade_env = TradeEnvironmentSetup.find_by_production_schedule_code_and_trade_env_code(self.production_schedule_code, self.trade_env_code)
      self.org = trade_env.organization_marketing
    end
    
  end
  
  def before_save
   
   #self.color_percentage = -1 if ! self.color_percentage
   #self.order_number = "n.a." if ! self.order_number
   #pack_order = ""
   #pack_order = "(" + self.pack_order + ")" if self.pack_order && self.pack_order.strip != ""
   #self.carton_setup_code = self.color_percentage.to_s + "_" + self.grade_code.to_s + "_" + self.standard_size_count_value.to_s + "_" + self.org.to_s + "_" +  self.sequence_number.to_s  + pack_order                        
   recalc_setup_code
   
  end
  
  
  def recalc_setup_code
    self.color_percentage = -1 if ! self.color_percentage
    self.order_number = "n.a." if ! self.order_number
    pack_order = ""
    pack_order = "(" + self.pack_order + ")" if self.pack_order && self.pack_order.strip != ""
    self.carton_setup_code = self.color_percentage.to_s + "_" + self.grade_code.to_s + "_" + self.standard_size_count_value.to_s + "_" + self.org.to_s + "_" +  self.sequence_number.to_s  + pack_order                        
  end
  
  
   def update_time
      
      
      timestamp = self.carton_setup_update_timestamp
      
      timestamp = CartonSetupUpdateTimestamp.new if timestamp == nil
      
      timestamp.carton_setup = self
      timestamp.update_time
      self.carton_setup_update_timestamp = timestamp
      self.carton_setup_update_timestamp.reload
   
   end
   
  
 def before_create
    
   self.color_percentage = -1 if ! self.color_percentage
   self.order_number = "n.a." if ! self.order_number
   self.carton_setup_code = self.color_percentage.to_s + "_" + self.grade_code.to_s + "_" + self.standard_size_count_value.to_s + "_" + self.org.to_s + "_" +  self.sequence_number.to_s                          
   self.treatment_type_code = "PACKHOUSE"
  
  
  end
  
  
  def CartonSetup.get_all_in_range(production_schedule_id,range_start_val,range_end_val,color_perc,grade)
  
    return CartonSetup.find_by_sql("select * from carton_setups where (production_schedule_id
                           = '#{production_schedule_id}' and standard_size_count_value <=
                           '#{range_start_val}' and standard_size_count_value >= 
                           '#{range_end_val}' and
                           color_percentage = '#{color_perc}' and
                           grade_code = '#{grade}' )")
  end
  
  
  def CartonSetup.re_sequence_group(schedule_code,color_perc,grade_code,std_count,org)
    self.transaction do
     grains = CartonSetup.find_all_by_production_schedule_code_and_color_percentage_and_grade_code_and_standard_size_count_value_and_org(schedule_code,color_perc,grade_code,std_count,org,:order => "sequence_number")
     new_sequence = 0
     grains.each do |grain|
         new_sequence += 1
         grain.sequence_number = new_sequence
         grain.recalc_setup_code
         grain.update
     end
     
   end
  end
   
  
  def re_sequence_if_needed(old_record)
  
     if old_record.org != self.org || old_record.color_percentage != self.color_percentage||old_record.grade_code != self.grade_code||old_record.standard_size_count_value != self.standard_size_count_value
     other_grain_max_seq = CartonSetup.max_sequence_for_grain(self.color_percentage,self.grade_code,self.standard_size_count_value,self.org,self.production_schedule_code)
     self.sequence_number = other_grain_max_seq + 1
     
     #now find all records of the old grain and re-sequence them, BUT ignore the record represented by this instance (same id)
     old_grain_records = CartonSetup.find_all_by_production_schedule_code_and_color_percentage_and_grade_code_and_standard_size_count_value_and_org(self.production_schedule_code,old_record.color_percentage,old_record.grade_code,old_record.standard_size_count_value,old_record.org,:order => "sequence_number")
     
     #  we must first set the current instance's record to a number that wont interfere with this re-numbering
        #process- this instance's number will be re-numbered correctly when this instance gets saved
      
     curr_instance = CartonSetup.find(self.id)
     curr_instance.sequence_number = 1000
     curr_instance.update
     
      new_sequence = 0
     old_grain_records.each do |old_grain|
     
      if old_grain.id != self.id
        
        new_sequence += 1
        old_grain.sequence_number = new_sequence
        old_grain.update
      
      end
      
     end
   end
  
  
  end
  
  def after_update
    #re-calculate retail-item setup and fg_setup- and delete carton label_setup and carton template
  
    if @re_calc_fg
      if self.retail_item_setup
        self.retail_item_setup.production_schedule_code = self.production_schedule_code
        self.retail_item_setup.ignore_item_product_create = false
        self.retail_item_setup.save
      end  
     if self.fg_setup
        self.fg_setup.production_schedule_code = self.production_schedule_code
        self.fg_setup.save
     end
    
    
   end
#---------------
# Luks Code   --
#---------------
     season_code_vals = self.production_schedule_code.split("_")
     season_code = season_code_vals[0] + "_" + season_code_vals[1]
     
     if self.order_number && self.order_number.upcase != "N.A."
       season_order_quantity = SeasonOrderQuantity.find_by_season_code_and_customer_order_number(season_code,self.order_number)
       
       if season_order_quantity 
         self.qty_required = season_order_quantity.quantity_required
         self.qty_produced = season_order_quantity.quantity_produced
       end
     end
#--------------   
   
  end
  
  def before_update
   #-----------------------------------------------------------------------------------------------
   #a) determine if org has changed, if so delete all dependent setups that needs an org
   #they are: 1) entire fg_setup, mark_codes of retail_item,retail unit and trade_unit
   #b) determine if grade or color_perentage or org has changed. If so, get the max sequence number
   #  with new record's grain: i.e: grade,color perc and size count. This record's sequence number
   #   must be one more that the max sequence number for the 'grain'
   #   2) Do a find of all the records with the original grain and re-number them, since the
   #      'removal' of the changed record will leave a gap
   #   3) If grade has changed, then the item_pack_product of retail_item_setup must be re-calulated
   #   4) If grade or color_perc has changed, then:
   #      a) fg_product of fg_setup must be recalculated and carton_template and carton_label_setup must
   #         be set to nil   
   #   
   #-----------------------------------------------------------------------------------------------      
   
   old_record = CartonSetup.find(self.id)
   
   if old_record.org != self.org
      if self.retail_item_setup
         self.retail_item_setup.mark_code = nil
         self.retail_item_setup.update
      end
     if self.retail_unit_setup
         self.retail_unit_setup.mark_code = nil
         self.retail_unit_setup.update
     end
     if self.trade_unit_setup
        self.trade_unit_setup.mark_code = nil
        self.trade_unit_setup.update
     end
     if self.fg_setup
        self.fg_setup.destroy
        self.fg_setup = nil
     end
   end
   
   
   self.retail_item_setup.ignore_item_product_create = true if self.retail_item_setup
   
   if old_record.org != self.org || old_record.color_percentage != self.color_percentage||old_record.grade_code != self.grade_code
    puts "grain change"
     other_grain_max_seq = CartonSetup.max_sequence_for_grain(self.color_percentage,self.grade_code,self.standard_size_count_value,self.org,self.production_schedule_code)
     self.sequence_number = other_grain_max_seq + 1
     self.recalc_setup_code
     
     #now find all records of the old grain and re-sequence them, BUT ignore the record represented by this instance (same id)
     old_grain_records = CartonSetup.find_all_by_production_schedule_code_and_color_percentage_and_grade_code_and_standard_size_count_value_and_org(self.production_schedule_code,old_record.color_percentage,old_record.grade_code,old_record.standard_size_count_value,old_record.org,:order => "sequence_number")
     
     #  we must first set the current instance's record to a number that wont interfere with this re-numbering
        #process- this instance's number will be re-numbered correctly when this instance gets saved
      
     curr_instance = CartonSetup.find(self.id)
     curr_instance.sequence_number = 10000
     curr_instance.update
     
      new_sequence = 0
     old_grain_records.each do |old_grain|
     
      if old_grain.id != self.id
        
        new_sequence += 1
        old_grain.sequence_number = new_sequence
        old_grain.update
      
      end
      
     end
    
   end
   
   #-------------------------------------------------------------
   #Non grain changes that also require IPC and FGC recalculation
   #-------------------------------------------------------------
   
   if (self.retail_item_setup && old_record.grade_code != self.grade_code)||(self.retail_item_setup && old_record.product_class_code != self.product_class_code)||(self.retail_item_setup && old_record.marketing_variety_code != self.marketing_variety_code)  
      puts "RECALC"
       @re_calc_fg = true
       update_time
   end
   
  
  end
  
  def CartonSetup.max_sequence_for_grain(color_perc,grade,std_count,org,schedule)
     query = "SELECT max(carton_setups.sequence_number)as maxval
           FROM
           public.carton_setups where 
           (public.carton_setups.production_schedule_code = '#{schedule}' AND
           carton_setups.standard_size_count_value = '#{std_count}'AND
            carton_setups.grade_code = '#{grade}' AND
            carton_setups.org = '#{org}' AND
            carton_setups.color_percentage = '#{color_perc}')"
            
     val = connection.select_one(query)
     if val["maxval"]== nil
       return 0
     else
       return val["maxval"].to_i 
     end
  
  end
  
  
  def CartonSetup.get_by_schedule_and_fg_product_code(schedule_code,fg_product_code)
  
    query = "SELECT carton_setups.id
             FROM
             public.fg_setups
             INNER JOIN public.carton_setups ON (public.fg_setups.carton_setup_id = public.carton_setups.id)
             WHERE
             (public.carton_setups.production_schedule_code = '#{schedule_code}') AND 
             (public.fg_setups.fg_product_code = '#{fg_product_code}')"
  
    return CartonSetup.find_by_sql(query)[0]
  
  end
  
 
 #-----------------------------------------------------------------------
 #This method handles both cloning to a new std count and cloning to an
 #existing count value
 # ----------------------------------------------------------------------
 
  def clone_setup_to_count(count,carton_setup_code = nil,schedule = nil)
  
   self.transaction do
   old_record = nil
   
   if carton_setup_code
    carton_setup = CartonSetup.find_by_carton_setup_code_and_production_schedule_id(carton_setup_code,schedule.id)
    
    old_record = CartonSetup.find(carton_setup.id)
    #store the grain attributes of the record about to be morphed, so that we can
    #re-sequence the group to which it belongs to, once deleted
    old_color = old_record.color_percentage
    old_grade = old_record.grade_code
    old_std_count = old_record.standard_size_count_value
    old_org = old_record.org
    
    old_record.destroy
    CartonSetup.re_sequence_group(self.production_schedule_code,old_color,old_grade,old_std_count,old_org)
  
   end
   
    carton_setup = self.clone 
    carton_setup.standard_size_count_value = count
    carton_setup.sequence_number = CartonSetup.max_sequence_for_grain(self.color_percentage,self.grade_code,count,self.org,self.production_schedule_code)+ 1
    if self.fg_setup
     carton_setup.cloned_target_market_code = self.fg_setup.target_market
     carton_setup.cloned_inventory_code = self.fg_setup.inventory_code
    
    end
    carton_setup.create
  
   #retail item setup
   retail_item_setup = nil
   carton_setup.retail_item_setup = nil
   if self.retail_item_setup
    retail_item_setup = self.retail_item_setup.clone
    retail_item_setup.production_schedule_code = self.production_schedule_code 
    retail_item_setup.ignore_item_product_create = false
    retail_item_setup.carton_setup = nil
    retail_item_setup.carton_setup = carton_setup
    retail_item_setup.size_ref = "NOS"
    retail_item_setup.save
   end
  
   #retail_unit_setup
   retail_unit_setup = nil
   carton_setup.retail_unit_setup = nil
   if self.retail_unit_setup
    retail_unit_setup = self.retail_unit_setup.clone 
    #retail_unit_setup.ignore_item_product_create = true
    retail_unit_setup.carton_setup = nil
    retail_unit_setup.carton_setup = carton_setup
    retail_unit_setup.create
   end
  
   #trade_unit_setup
   trade_unit_setup = nil
   carton_setup.trade_unit_setup = nil
   if self.trade_unit_setup
    trade_unit_setup = self.trade_unit_setup.clone 
    #trade_unit_setup.ignore_item_product_create = true
    trade_unit_setup.carton_setup = nil
    trade_unit_setup.carton_setup = carton_setup
    trade_unit_setup.create
   end
  
   #fg_setup
   
   #-----------------------------------------------------
   #FG SETUP EXCLUDED SINCE USER DO NOT WANT A MERGE HERE
   #-----------------------------------------------------
#   fg_setup = nil
#   carton_setup.fg_setup = nil
#   if self.fg_setup
#    fg_setup = self.fg_setup.clone 
#    fg_setup.production_schedule_code = self.production_schedule_code
#    #fg_setup.ignore_item_product_create = true
#    fg_setup.carton_setup = nil
#    fg_setup.carton_setup = carton_setup
#    fg_setup.save #save used so that fg_product can be calculated
#   end
  
   #pallet
   pallet_setup = nil
   carton_setup.pallet_setup = nil
   if self.pallet_setup
    pallet_setup = self.pallet_setup.clone 
    #pallet_setup.ignore_item_product_create = true
    pallet_setup.carton_setup = nil
    pallet_setup.carton_setup = carton_setup
    pallet_setup.create
   end
  
  
   #palletizing_criterium
   palletizing_criteria = nil
   carton_setup.palletizing_criterium = nil
   if self.palletizing_criterium
    palletizing_criterium = self.palletizing_criterium.clone 
    #pallet_setup.ignore_item_product_create = true
    palletizing_criterium.carton_setup = nil
    palletizing_criterium.carton_setup = carton_setup
    palletizing_criterium.create
   end
  
  end
  
  end
  
  def clone_setup
   self.transaction do
   carton_setup = self.clone
   
   carton_setup.sequence_number = CartonSetup.max_sequence_for_grain(self.color_percentage,self.grade_code,self.standard_size_count_value,self.org,self.production_schedule_code)+ 1
   carton_setup.create
   
   #retail item setup
   retail_item_setup = nil
   carton_setup.retail_item_setup = nil
   if self.retail_item_setup
    retail_item_setup = self.retail_item_setup.clone 
    retail_item_setup.ignore_item_product_create = true
    retail_item_setup.carton_setup = nil
    retail_item_setup.carton_setup = carton_setup
    retail_item_setup.create
   end
  
   #retail_unit_setup
   retail_unit_setup = nil
   carton_setup.retail_unit_setup = nil
   if self.retail_unit_setup
    retail_unit_setup = self.retail_unit_setup.clone 
    #retail_unit_setup.ignore_item_product_create = true
    retail_unit_setup.carton_setup = nil
    retail_unit_setup.carton_setup = carton_setup
    retail_unit_setup.create
   end
  
   #trade_unit_setup
   trade_unit_setup = nil
   carton_setup.trade_unit_setup = nil
   if self.trade_unit_setup
    trade_unit_setup = self.trade_unit_setup.clone 
    #trade_unit_setup.ignore_item_product_create = true
    trade_unit_setup.carton_setup = nil
    trade_unit_setup.carton_setup = carton_setup
    trade_unit_setup.create
   end
  
   #fg_setup
   fg_setup = nil
   carton_setup.fg_setup = nil
   if self.fg_setup
    fg_setup = self.fg_setup.clone 
    #fg_setup.ignore_item_product_create = true
    fg_setup.carton_setup = nil
    fg_setup.carton_setup = carton_setup
    fg_setup.create
   end
  
   #pallet
   pallet_setup = nil
   carton_setup.pallet_setup = nil
   if self.pallet_setup
    pallet_setup = self.pallet_setup.clone 
    #pallet_setup.ignore_item_product_create = true
    pallet_setup.carton_setup = nil
    pallet_setup.carton_setup = carton_setup
    pallet_setup.create
   end
  
   #----------------------------
   #now clone the mapping tables
   #----------------------------
   
   #carton_template
   carton_template = nil
   carton_setup.carton_template = nil
   if self.carton_template
    carton_template = self.carton_template.clone 
    #pallet_setup.ignore_item_product_create = true
    carton_template.carton_setup = nil
    carton_template.carton_setup = carton_setup
    carton_template.create
   end
   
   #carton_label_setup
   carton_label_setup = nil
   carton_setup.carton_label_setup = nil
   if self.carton_label_setup
    carton_label_setup = self.carton_label_setup.clone 
    #pallet_setup.ignore_item_product_create = true
    carton_label_setup.carton_setup = nil
    carton_label_setup.carton_setup = carton_setup
    carton_label_setup.create
   end
  
   #pallet_label_setup
   pallet_label_setup = nil
   carton_setup.pallet_label_setup = nil
   if self.pallet_label_setup
    pallet_label_setup = self.pallet_label_setup.clone 
    #pallet_setup.ignore_item_product_create = true
    pallet_label_setup.carton_setup = nil
    pallet_label_setup.carton_setup = carton_setup
    pallet_label_setup.create
   end
   
   #pallet_template
   pallet_template = nil
   carton_setup.pallet_template = nil
   if self.pallet_template
    pallet_template = self.pallet_template.clone 
    #pallet_setup.ignore_item_product_create = true
    pallet_template.carton_setup = nil
    pallet_template.carton_setup = carton_setup
    pallet_template.create
   end
   
   #palletizing_criterium
   palletizing_criteria = nil
   carton_setup.palletizing_criterium = nil
   if self.palletizing_criterium
    palletizing_criterium = self.palletizing_criterium.clone 
    #pallet_setup.ignore_item_product_create = true
    palletizing_criterium.carton_setup = nil
    palletizing_criterium.carton_setup = carton_setup
    palletizing_criterium.create
   end
  
  end
  
  end
  
end




