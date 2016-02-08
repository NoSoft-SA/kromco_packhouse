class FgSetup < ActiveRecord::Base

  belongs_to :carton_setup
  belongs_to :fg_product
  
  
  
  attr_reader :production_schedule_code,:org,:color_percentage,:grade_code,:std_count,
              :sequence_number,:order_number,:carton_fruit_mass_label,:new_ipc,:carton_setup_code
              
  attr_writer :production_schedule_code,:org,:color_percentage,:grade_code,:std_count,
              :sequence_number,:order_number,:carton_fruit_mass_label,:new_ipc,:carton_setup_code
  
  attr_accessor :tu_nett_mass,:tu_gross_mass,:diameter,:extended_fg_id,:current_iso_week
  
     
  def after_find
   
    if self.has_attribute?("ri_diameter_range")
      
      self.diameter = self.ri_diameter_range.to_s if self.ri_diameter_range
      self.diameter = "" if !self.diameter
     
      self.diameter = self.ri_weight_range.to_s if self.ri_weight_range && self.diameter == ""
      
    else
    end
    
    
  end
  
  def production_schedule_code
    if @production_schedule_code == nil
      @production_schedule_code = self.carton_setup.production_schedule_code
    end
    return @production_schedule_code
  end
  
  def validate
         
		 ModelHelper::Validations.validate_combos([{:target_market => self.target_market}],self) 
		 ModelHelper::Validations.validate_combos([{:inventory_code => self.inventory_code}],self)
		 ModelHelper::Validations.validate_combos([{:retailer_sell_by_code => self.retailer_sell_by_code}],self)
	     set_fg_mark
	     set_orgs
	     
	     ext_err = false
	     if self.tu_nett_mass.to_f == 0
	      errors.add("tu_nett_mass","You must enter a value")
	      ext_err = true
	     end
	     
	     if self.tu_gross_mass.to_f == 0
	      errors.add("tu_gross_mass","You must enter a value")
	      ext_err = true
	     end
	      
	     
	     self.ri_diameter_range = "" if !self.ri_diameter_range
	     self.ri_weight_range = "" if !self.ri_weight_range
	     
	     if (self.ri_diameter_range.strip == "") && (self.ri_weight_range.strip == "")
	       errors.add_to_base("You must enter a value for either ri_diameter_range or ri_weight_range")
	     elsif !ext_err
	       set_extended_fg
	     end
	     
	     org = Organization.find_by_short_description(self.carton_setup.org)
         contact_method = ContactMethodsParty.find_by_party_name_and_contact_method_type_code(org.party.party_name,"CARTON_LABEL_ADDRESS").contact_method
         
         if !contact_method
           errors.add_to_base("You must define a contact method of type 'CARTON_LABEL_ADDRESS' for the marketing org(" + self.carton_setup.org + ")")
         else
        
          address_1 = contact_method.contact_method_code
          address_2 = contact_method.contact_method_description
          if(address_1 == nil||address_2 == nil)
            errors.add_to_base("You must both address lines for the contact method of type: 'CARTON_LABEL_ADDRESS' for the marketing org(" + self.carton_setup.org + ")")
          end
       end
  end
 
 
 def calc_extended_fg
     
     fg_code = ""
     
     set_fg_product
     units = self.carton_setup.retail_unit_setup.units_per_carton
	 units = "*" if !units ||units == 0
	 
	 fg_code += self.carton_setup.retail_item_setup.item_pack_product_code + "_" 
	 fg_code += units.to_s
     fg_code += self.carton_setup.retail_unit_setup.unit_pack_product_code + "_"
     fg_code += self.carton_setup.trade_unit_setup.carton_pack_product_code
	 extended_fg_code = fg_code + "_" + self.carton_setup.org + "_" + self.fg_mark_code.to_s 
     return extended_fg_code
 end
 
  def set_extended_fg
  
	 extended_fg_code = calc_extended_fg
	
	 #---------------------
	 #calculate old fg code
	 #---------------------

	actual_count_code = self.carton_setup.retail_item_setup.item_pack_product.actual_count.to_s
    if !(self.carton_setup.retail_item_setup.item_pack_product.size_ref == "NOS"||self.carton_setup.retail_item_setup.item_pack_product.size_ref == nil)
      actual_count_code = self.carton_setup.retail_item_setup.item_pack_product.size_ref
    end
    
	rmt_setup = RmtSetup.find_by_production_schedule_name(self.carton_setup.production_schedule_code)
	brand_code = Mark.find_by_mark_code(self.carton_setup.trade_unit_setup.mark_code).brand_code
	self.fg_code_old = rmt_setup.commodity_code + " " + self.carton_setup.marketing_variety_code + " " + brand_code + " " + self.carton_setup.trade_unit_setup.old_pack_code.to_s + " " + actual_count_code
	
	
	 @extended_fg_record = ExtendedFg.create_if_needed(self.fg_product_code,extended_fg_code,self.fg_mark_code.to_s,self.carton_setup.retail_unit_setup.units_per_carton.to_s,self.carton_setup.org,self.fg_code_old)
     @extended_fg_record.tu_nett_mass = self.tu_nett_mass.to_f
     @extended_fg_record.tu_gross_mass = self.tu_gross_mass.to_f
     @extended_fg_record.ri_diameter_range = self.ri_diameter_range
     @extended_fg_record.ri_weight_range = self.ri_weight_range
     @extended_fg_record.ru_description = self.marking
     @extended_fg_record.save
     self.extended_fg_code = @extended_fg_record.extended_fg_code
     
  end
  
  def set_orgs
     trade_env = TradeEnvironmentSetup.find_by_production_schedule_id_and_trade_env_code(self.carton_setup.production_schedule.id,self.carton_setup.trade_env_code)
     self.retailer_org = trade_env.organization_retailer
     self.marketing_org = self.carton_setup.org
  
  end
  
    
  def set_fg_mark
    
      err_msg = nil
	  ri_mark = self.carton_setup.retail_item_setup.mark_code
	  ru_mark = self.carton_setup.retail_unit_setup.mark_code
	  tu_mark = self.carton_setup.trade_unit_setup.mark_code
	
	  fg_mark_code = ""
	 
	 
	  if ri_mark && ru_mark && tu_mark
	    mark_code = FgMark.create_if_needed(ri_mark,ru_mark,tu_mark)
	    fg_mark = FgMark.find_by_ri_mark_code_and_ru_mark_code_and_tu_mark_code(ri_mark,ru_mark,tu_mark)
	    if fg_mark
	      self.fg_mark_code = fg_mark.fg_mark_code
	    else
	      err_msg = "No fg_mark_code exists for combined values of <br>ri_mark(" + ri_mark + ") and ru_mark(" + ru_mark + ") and tu_mark(" + tu_mark + ")"
	    end
	  else
	    missing = ""
	    missing += "RI_MARK NOT SET <BR>" if !ri_mark
	    missing += "RU_MARK NOT SET <BR>" if !ru_mark
	    missing += "TU_MARK NOT SET" if !tu_mark
	    err_msg = missing
	     
	end
  
    errors.add_to_base(err_msg) if err_msg
  
  end
  
  def before_save
   
   set_fg_product
   self.gtin = get_gtin
   self.carton_setup.fg_product_code = self.fg_product_code
   self.carton_setup.update
   
   if self.carton_setup.production_schedule.production_schedule_status_code = "re_opened"
    #PackGroup.re_sync_with_carton(self.carton_setup,self.carton_setup.production_schedule_code)
   end
   
   puts "errors: " + self.errors.length.to_s
  end
  
  
  #----------------------------------------------------------------------
  #This method builds carton and pallet template and label setup records
  #if they do not exist already
  #----------------------------------------------------------------------
  def build_templates_and_labels
    
   #--------------------------------------------------------------
   #Fetch data needed for build operations
   #--------------------------------------------------------------
   self.production_schedule_code = self.carton_setup.production_schedule_code
   self.org = self.carton_setup.org
   self.color_percentage = self.carton_setup.color_percentage
   self.grade_code = self.carton_setup.grade_code
   self.std_count = self.carton_setup.standard_size_count_value
   self.sequence_number = self.carton_setup.sequence_number
   self.order_number =  self.carton_setup.order_number
   
   
   @rmt_setup = RmtSetup.find_by_production_schedule_name(self.production_schedule_code)
    self.transaction do
      build_carton_template
      build_carton_label 
      build_pallet_template
      build_pallet_label
      
      self.carton_setup.update
    end
  
  end
  
  def FgSetup.fg_codes_for_station_link_context(pack_station,run)
   
    results = FgSetup.fg_codes_for_station_context(run,pack_station.grade,pack_station.color_percentage,pack_station.marketing_variety,pack_station.size_count,pack_station.drop_code)
    puts "initial fg count: " + results.length.to_s
    fin_results = nil
    if pack_station.additional_groups 
      pack_station.additional_groups.each do |group|
        puts "ADDING ADDITIONAL GROUP"
        results.concat(FgSetup.fg_codes_for_station_context(run,group[1],group[0],pack_station.marketing_variety,pack_station.size_count,pack_station.drop_code))
      end
     
      #remove all duplicates
      distincts = Hash.new
      fin_results = Array.new
      results.each do |result|
      if !distincts.has_key?(result.fg_product_code)
       distincts.store(result.fg_product_code,result)
       fin_results.push(result)
      end
    end
  else
   fin_results = results
  end
  return fin_results
 end
  
  
#  def FgSetup.fg_codes_for_station_context(schedule,grade,color_percentage,marketing_variety,count,drop_code)
#	
#	 query = "SELECT DISTINCT 
#              public.fg_setups.fg_product_code
#              FROM
#              public.fg_setups
#              INNER JOIN public.carton_setups ON (public.fg_setups.carton_setup_id = public.carton_setups.id)
#              WHERE
#              (public.carton_setups.production_schedule_code = '#{schedule}') AND 
#              (public.carton_setups.grade_code = '#{grade}') AND 
#              (public.carton_setups.color_percentage = '#{color_percentage}'))"
#	
#	
#	
#	end



  def FgSetup.fg_codes_for_station_context(run,grade,color_percentage,marketing_variety,count,drop_code)
  
   
   query = "SELECT DISTINCT
              public.fg_setups.fg_product_code
      FROM
    public.fg_setups
    INNER JOIN public.carton_setups ON (public.fg_setups.carton_setup_id = public.carton_setups.id)
    INNER JOIN public.pack_groups ON (public.carton_setups.color_percentage = public.pack_groups.color_sort_percentage)
    AND (public.carton_setups.grade_code = public.pack_groups.grade_code)
    INNER JOIN public.pack_group_outlets ON (public.pack_groups.id = public.pack_group_outlets.pack_group_id)
    AND (public.carton_setups.standard_size_count_value = public.pack_group_outlets.standard_size_count_value)
    WHERE
     (public.carton_setups.color_percentage = '#{color_percentage}') AND 
     (public.carton_setups.production_schedule_code = '#{run.production_schedule_name}') AND
     (public.carton_setups.grade_code = '#{grade}') AND 
     (public.pack_groups.production_run_id = '#{run.id}') AND 
     ((public.pack_group_outlets.outlet1 = '#{drop_code}') OR 
     (public.pack_group_outlets.outlet2 = '#{drop_code}') OR 
     (public.pack_group_outlets.outlet3 = '#{drop_code}') OR 
     (public.pack_group_outlets.outlet4 = '#{drop_code}') OR 
     (public.pack_group_outlets.outlet5 = '#{drop_code}') OR 
     (public.pack_group_outlets.outlet6 = '#{drop_code}') OR
     (public.pack_group_outlets.outlet7 = '#{drop_code}') OR
     (public.pack_group_outlets.outlet8 = '#{drop_code}') OR
     (public.pack_group_outlets.outlet9 = '#{drop_code}') OR
    (public.pack_group_outlets.outlet10 = '#{drop_code}') OR
      (public.pack_group_outlets.outlet11 = '#{drop_code}') OR     
     (public.pack_group_outlets.outlet12 = '#{drop_code}'))"
     
      return FgSetup.find_by_sql(query)
	
 end
 
#	  def FgSetup.fg_codes_for_binfill_station_context(schedule,grade,color_percentage,marketing_variety)
#	
#	    query ="SELECT DISTINCT 
#              public.fg_setups.fg_product_code
#              FROM
#              public.fg_setups
#              INNER JOIN public.carton_setups ON (public.fg_setups.carton_setup_id = public.carton_setups.id)
#              WHERE
#              (public.carton_setups.production_schedule_code = '#{schedule}') AND 
#              (public.carton_setups.grade_code = '#{grade}') AND 
#              (public.carton_setups.color_percentage = '#{color_percentage}') AND 
#              (public.carton_setups.marketing_variety_code = '#{marketing_variety}')"
#	
#	          return FgSetup.find_by_sql(query)
#	
#	end
	
  
  def build_pallet_label
    
    #puc when mixing was alowed: at runtime:
    #get a list of the 9 farms with most cartons on pallet and concatenate puc and amount of cartons of each farm as a single string
    
    pallet_label_setup = nil
    if self.carton_setup.pallet_label_setup != nil
      pallet_label_setup = self.carton_setup.pallet_label_setup
      
    else
      pallet_label_setup = PalletLabelSetup.new
    end
    
    variety_1 = nil
    variety_2 = nil
    
    if @marketing_variety_description.length > 10
      variety_1 = @marketing_variety_description.slice(0..9)
      variety_2 = @marketing_variety_description.slice(10..@marketing_variety_description.length)
    else
      variety_1 = @marketing_variety_description
    end
    
    pallet_label_setup.variety_plusten_part_1 = variety_1
    pallet_label_setup.variety_plusten_part_2 = variety_2
    pallet_label_setup.sell_by_code = self.retailer_sell_by_code #this should be a freeform text field 
    @pallet_template.export_attributes(pallet_label_setup)
    pallet_label_setup.label_code = self.carton_setup.pallet_setup.label_code
    pallet_label_setup.carton_setup = self.carton_setup
    pallet_label_setup.save
    self.carton_setup.pallet_label_setup = pallet_label_setup
    self.carton_setup.pallet_label_setup.save
    
  end
  
  
  def build_pallet_template
  
    
    pallet_template = nil
    if self.carton_setup.pallet_template != nil
      pallet_template = self.carton_setup.pallet_template
      
    else
      pallet_template = PalletTemplate.new
    end
     
    pallet_template.store_type_code = "cold_store"
    pallet_template.party_name = "KR"
    
    pallet_template.pallet_base_code = self.carton_setup.pallet_setup.pallet_format_product.pallet_base_code
    pallet_template.pallet_label_code = self.carton_setup.pallet_setup.label_code
    pallet_template.qc_status_code = 0.to_s
    pallet_template.pi = 0.to_s
    #---------------------
    #fields added March 07
    ##---------------------------------------------------------------------------
    pallet_template.ca_cold_room_code = @rmt_setup.ca_cold_room_code
    pallet_template.inspect_type_code = self.carton_setup.pallet_setup.inspection_type_code
    pallet_template.old_pack_code = self.carton_setup.retail_item_setup.basic_pack_code
    pallet_template.pallet_format_product_code = self.carton_setup.pallet_setup.pallet_format_product_code
    pallet_template.pallet_format_product = self.carton_setup.pallet_setup.pallet_format_product
    pallet_template.marketing_variety_code = self.carton_setup.marketing_variety_code
    
   
    #March additions to here----------------------------------------------------
    pallet_template.country_origin_code = "za"
    pallet_template.pallet_format_product_code = self.carton_setup.pallet_setup.pallet_format_product_code
    pallet_template.carton_setup = self.carton_setup
    @carton_template.export_attributes(pallet_template)
    
    pallet_template.actual_size_count_code =  @carton_template.actual_size_count_code
    pallet_template.size_count_code = self.carton_setup.standard_size_count_value.to_s
    pallet_template.save
    @pallet_template = pallet_template
    #---------------------------------------------------------------------------------------------------
    #data added at runtime:
    #-> num cartons on pallet
    #-> storing of cartons where attributes differ on same pallet - to be discussed
    #   (currently more than one pallet will be created and a sequence is used to group what should be
    #    one one pallet)
    #---------------------------------------------------------------------------------------------------
  
  end
  
 
  def set_fg_product
    puts "in set_fg_product"
    if !self.new_ipc
     ipc = self.carton_setup.retail_item_setup.item_pack_product_code 
    else
     ipc = self.new_ipc
    end
    
    upc =  self.carton_setup.retail_unit_setup.unit_pack_product_code 
    cpc =   self.carton_setup.trade_unit_setup.carton_pack_product_code
    
    product = nil
    product = FgProduct.find_by_item_pack_product_code_and_unit_pack_product_code_and_carton_pack_product_code(ipc,upc,cpc)
    
   
    if !product
      puts "new fg"
      product = FgProduct.new
      product.item_pack_product = self.carton_setup.retail_item_setup.item_pack_product
      product.unit_pack_product = self.carton_setup.retail_unit_setup.unit_pack_product 
      product.carton_pack_product = self.carton_setup.trade_unit_setup.carton_pack_product  
      
      product.item_pack_product_code = self.carton_setup.retail_item_setup.item_pack_product_code
      product.unit_pack_product_code = self.carton_setup.retail_unit_setup.unit_pack_product_code 
      product.carton_pack_product_code = self.carton_setup.trade_unit_setup.carton_pack_product_code 
      product.save 
                                        
    end
    
     
     self.fg_product = product
     self.fg_product_code = product.fg_product_code
     #-----------------------------
     #set extended and old fg codes 
     #-----------------------------
     
  end
   
   
  def build_carton_label
   begin
    carton_label_setup = nil
    if self.carton_setup.carton_label_setup != nil
      carton_label_setup = self.carton_setup.carton_label_setup
      
    else
      carton_label_setup = CartonLabelSetup.new
    end
  
    carton_label_setup.gtin = self.gtin
    carton_label_setup.label_code = self.carton_setup.trade_unit_setup.standard_label_code
    marketing_variety_description = @marketing_variety_description.to_s
    carton_label_setup.variety_short_long = self.carton_setup.marketing_variety_code + "_" + @marketing_variety_description
    carton_label_setup.commodity_code  = self.carton_setup.retail_item_setup.item_pack_product.commodity_code
    carton_label_setup.commodity_description = Commodity.find_by_commodity_code(carton_label_setup.commodity_code).commodity_description_long
    carton_label_setup.mark_code = self.carton_setup.trade_unit_setup.mark_code
    carton_label_setup.unit_pack_product_code = self.carton_setup.retail_unit_setup.unit_pack_product_code
    #carton_label_setup.old_pack_code = self.carton_setup.trade_unit_setup.pack_material_product.old_pack_code.to_s
    #-------------------------------------------------------------------
    #If the item pack product has a size ref, use it, otherwise use the
    #actual count
    #--------------------------------------------------------------------
    item_pack = self.carton_setup.retail_item_setup.item_pack_product
    actual_count = ""
    if item_pack.size_ref == "NOS"||item_pack.size_ref == nil #TODO: this value was null in test why?
     actual_count = item_pack.actual_count.to_s
     puts "no size ref"
    else
     actual_count = item_pack.size_ref.to_s
    end
    
    puts "actual count: " + actual_count
    carton_label_setup.actual_size_count_code = actual_count
    carton_label_setup.inventory_code = self.inventory_code 
    carton_label_setup.grade_code = self.carton_setup.grade_code
    carton_label_setup.pick_reference = nil #see build_carton_template note
    carton_label_setup.cold_store_code = @rmt_setup.cold_store_code
    carton_label_setup.target_market_code = self.target_market
    carton_label_setup.class_code = self.carton_setup.retail_item_setup.item_pack_product.product_class.product_class_description
    carton_label_setup.brand_code = @brand_code
    carton_label_setup.pallet_format_product_code = self.carton_setup.pallet_setup.pallet_format_product_code
    std_count_val = self.carton_setup.standard_size_count_value
    commodity = carton_label_setup.commodity_code
    std_count = StandardCount.find_by_standard_count_value_and_commodity_code(std_count_val,commodity)
    if !std_count
      raise "standard count could not be found for std count value: " + std_count_val.to_s + " and commodity: " + commodity + "<br> Raised from: 'build_carton_label'"
    end
    
    #diameter
    carton_label_setup.diameter = ""
     if @extended_fg_record.ri_diameter_range||@extended_fg_record.ri_weight_range
      carton_label_setup.diameter = @extended_fg_record.ri_diameter_range if @extended_fg_record.ri_diameter_range && @extended_fg_record.ri_diameter_range.strip() != ""
      carton_label_setup.diameter = @extended_fg_record.ri_weight_range if @extended_fg_record.ri_weight_range && @extended_fg_record.ri_weight_range.strip() != ""
     end
    
   
    carton_label_setup.organization_code = self.carton_setup.org
    carton_label_setup.gtin_code= self.gtin
    carton_label_setup.fg_product_code = self.fg_product_code
    org = Organization.find_by_short_description(self.carton_setup.org)
    contact_method = ContactMethodsParty.find_by_party_name_and_contact_method_type_code(org.party.party_name,"CARTON_LABEL_ADDRESS").contact_method
     
    carton_label_setup.organization_address_1 = contact_method.contact_method_code
    carton_label_setup.organization_address_2 = contact_method.contact_method_description
    carton_label_setup.organization_address_2 = "" if !carton_label_setup.organization_address_2
    
    marking = ""
    marking = self.carton_setup.retail_unit_setup.pack_material_product_code if self.carton_setup.retail_unit_setup.pack_material_product_code
    if marking != "" 
     if self.carton_setup.retail_unit_setup.units_per_carton
       marking = self.carton_setup.retail_unit_setup.units_per_carton.to_s + " X " + marking
     end
    end
     
    marking = @extended_fg_record.ru_description if @extended_fg_record.ru_description && marking == "" 
    
    carton_label_setup.marking = marking
    carton_label_setup.old_pack_code = @carton_template.old_pack_code
    
    
    carton_label_setup.carton_setup = self.carton_setup
    carton_label_setup.save
    
    #----------------------------------------------------------------------------------
    #Missing or run-time accessible info:
    #-> packer: scanned in at runtime
    #-> line_phc: attribute of line, belonging to a run- can only be set during runtime
    #-> puc nr: hangs on production_run: only accessible at runtime
    #-> carton number: generated at runtime
    #-> batch number: must be calculated at runtime: use the id of the production run
    #                                                number must be 10 characters
    #-----------------------------------------------------------------------------------
   rescue
     raise "Method 'build_carton_label' failed. Exception reported: <br> : " + $!
   end
  end
  

  def set_label_values_for_run(run,label_setup)
     gtin_readable = run.batch_code
     label_setup.gtin_readable ="^01" + label_setup.gtin + "10" +  run.batch_code if label_setup.gtin && label_setup.gtin.strip != ""
     label_setup.batch_code = run.batch_code
     iso_week = Date.today.cweek.to_s
     iso_week = "0" + iso_week if iso_week.length() == 1
     day = Time.now.wday.to_s
     day = "7" if day == "0"
     label_setup.pc_code = run.line_code if label_setup.pc_code_num == "-1"
     label_setup.pick_ref = iso_week.slice(1,1) + day + label_setup.pc_code + iso_week.slice(0,1)
     fpa = FarmPucAccount.get_account_for_farm_and_marketer(run.farm_code,label_setup.organization_code)
     if fpa
       puc = Puc.finad_by_puc_code(fpa.puc_code)
       label_setup.puc_code = puc.puc_code
       label_setup.egap = puc.egap
       label_setup.phc = run.line.line_phc
       label_setup.nature_choice_certificate = puc.nature_choice_certificate_code if puc.nature_choice_certificate_code
     end

     
   end
   
  def get_carton_label_preview
     begin

     new_record = false
    carton_label_setup = nil
    if self.carton_setup.carton_label_setup != nil
      carton_label_setup = self.carton_setup.carton_label_setup
     
    else
      carton_label_setup = CartonLabelSetup.new
       new_record = true
    end
    
    carton_label_setup.batch_code = "<font color = 'red'>[no run]</font>"
    carton_label_setup.gtin_readable = "<font color = 'red'>[no run]</font>"
    carton_label_setup.pick_ref = "<font color = 'red'>[no run]</font>"
    carton_label_setup.phc = "<font color = 'red'>[no run]</font>"
    carton_label_setup.puc_code = "<font color = 'red'>[no run]</font>"
    carton_label_setup.egap = "<font color = 'red'>[no run]</font>&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;&nbsp; &nbsp;"
    carton_label_setup.nature_choice_certificate = "&nbsp; &nbsp;&nbsp; &nbsp;<font color = 'red'>[no run]</font>"
    
    if new_record
          marketing_variety_description = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(self.carton_setup.marketing_variety_code,self.carton_setup.commodity_code).marketing_variety_description.to_s
          carton_label_setup.gtin = self.gtin if self.gtin && self.gtin.strip != ""
          carton_label_setup.label_code = self.carton_setup.trade_unit_setup.standard_label_code
          carton_label_setup.variety_short_long = self.carton_setup.marketing_variety_code + "_" + marketing_variety_description.to_s
          carton_label_setup.commodity_code  = self.carton_setup.retail_item_setup.item_pack_product.commodity_code
          carton_label_setup.commodity_description = Commodity.find_by_commodity_code(carton_label_setup.commodity_code).commodity_description_long
          carton_label_setup.mark_code = self.carton_setup.trade_unit_setup.mark_code
          carton_label_setup.unit_pack_product_code = self.carton_setup.retail_unit_setup.unit_pack_product_code
          #carton_label_setup.old_pack_code = self.carton_setup.trade_unit_setup.pack_material_product.old_pack_code.to_s
          #-------------------------------------------------------------------
          #If the item pack product has a size ref, use it, otherwise use the
          #actual count
          #--------------------------------------------------------------------
          item_pack = self.carton_setup.retail_item_setup.item_pack_product
          actual_count = ""
          if item_pack.size_ref == "NOS"||item_pack.size_ref == nil #TODO: this value was null in test why?
           actual_count = item_pack.actual_count.to_s
           puts "no size ref"
          else
           actual_count = item_pack.size_ref.to_s
          end

          puts "actual count: " + actual_count
          carton_label_setup.actual_size_count_code = actual_count
          carton_label_setup.inventory_code = self.inventory_code
          carton_label_setup.grade_code = self.carton_setup.grade_code
          carton_label_setup.pick_reference = nil #see build_carton_template note

          carton_label_setup.cold_store_code = self.carton_setup.production_schedule.rmt_setup.cold_store_code
    #    rmt_setup = RmtSetup.find_by_production_schedule_name(self.production_schedule_code)
    #    carton_label_setup.cold_store_code = rmt_setup.cold_store_code
    #
          carton_label_setup.target_market_code = self.target_market
          carton_label_setup.class_code = self.carton_setup.retail_item_setup.item_pack_product.product_class.product_class_description
          carton_label_setup.brand_code = brand_code = Mark.find_by_mark_code(self.carton_setup.trade_unit_setup.mark_code).brand_code
          carton_label_setup.pallet_format_product_code = self.carton_setup.pallet_setup.pallet_format_product_code
          std_count_val = self.carton_setup.standard_size_count_value
          commodity = carton_label_setup.commodity_code
          std_count = StandardCount.find_by_standard_count_value_and_commodity_code(std_count_val,commodity)
          if !std_count
            raise "standard count could not be found for std count value: " + std_count_val.to_s + " and commodity: " + commodity + "<br> Raised from: 'build_carton_label'"
          end

          #diameter
           carton_label_setup.diameter = ""
           @extended_fg_record = ExtendedFg.find_by_extended_fg_code(self.extended_fg_code)
           if @extended_fg_record.ri_diameter_range||@extended_fg_record.ri_weight_range
            carton_label_setup.diameter = @extended_fg_record.ri_diameter_range if @extended_fg_record.ri_diameter_range
            carton_label_setup.diameter = @extended_fg_record.ri_weight_range if @extended_fg_record.ri_weight_range
           end
           carton_label_setup.extended_fg_code = @extended_fg_record.extended_fg_code

             carton_label_setup.organization_code = self.carton_setup.org
            carton_label_setup.gtin_code= self.gtin
            carton_label_setup.fg_product_code = self.fg_product_code
            org = Organization.find_by_short_description(self.carton_setup.org)
            contact_method = ContactMethodsParty.find_by_party_name_and_contact_method_type_code(org.party.party_name,"CARTON_LABEL_ADDRESS").contact_method

            carton_label_setup.organization_address_1 = contact_method.contact_method_code
            carton_label_setup.organization_address_2 = contact_method.contact_method_description
            carton_label_setup.organization_address_2 = "" if !carton_label_setup.organization_address_2

            marking = ""
            marking = self.carton_setup.retail_unit_setup.pack_material_product_code if self.carton_setup.retail_unit_setup.pack_material_product_code
            if marking != ""
             if self.carton_setup.retail_unit_setup.units_per_carton
               marking = self.carton_setup.retail_unit_setup.units_per_carton.to_s + " X " + marking
             end
            end

            marking = @extended_fg_record.ru_description if @extended_fg_record.ru_description && marking == ""

            carton_label_setup.marking = marking
            carton_label_setup.old_pack_code = self.carton_setup.trade_unit_setup.old_pack_code


            carton_label_setup.carton_setup = self.carton_setup
    end
    

     ru_type = self.carton_setup.retail_unit_setup.unit_pack_product.type_code
     carton_label_setup.print_count = "COUNT" if ru_type == "T"
     
    carton_label_setup.pc_code = "PC" + self.carton_setup.production_schedule.rmt_setup.rmt_product.ripe_point.pc_code.pc_code + "_" + self.carton_setup.production_schedule.rmt_setup.rmt_product.ripe_point.pc_code.pc_name
    carton_label_setup.pc_code_num = self.carton_setup.production_schedule.rmt_setup.rmt_product.ripe_point.pc_code.pc_code 
    
    carton_label_setup.marking_heading = ""
    if carton_label_setup.marking && carton_label_setup.marking.strip != "" && carton_label_setup.marking != "*"
     carton_label_setup.marking_heading = "MARKING"
    end

    carton_label_setup.diameter_heading = ""
    if carton_label_setup.diameter && carton_label_setup.diameter.strip != "" && carton_label_setup.diameter != "*"
     carton_label_setup.diameter_heading = "DIAMETER"
    end
  #--
   
    #carton_label_setup.save
    return carton_label_setup
#    #----------------------------------------------------------------------------------
#    #Missing or run-time accessible info:
#    #-> packer: scanned in at runtime
#    #-> line_phc: attribute of line, belonging to a run- can only be set during runtime
#    #-> puc nr: hangs on production_run: only accessible at runtime
#    #-> carton number: generated at runtime
#    #-> batch number: must be calculated at runtime: use the id of the production run
#    #                                                number must be 10 characters
#    #-----------------------------------------------------------------------------------
   rescue
     raise "Method 'build_carton_label_preview' failed. Exception reported: <br> : " + $!
   end
  end
##====================
  
  def after_save
    self.carton_setup.update_time
  end
  
  def after_create
   self.carton_setup.update_time
  end
  #--------------------------------------------------------------
  #Fields to add at runtime (run running time)
  #pick ref
  #production_schedule_no = our run number (schedule prepended)
  #
  #---------------------------------------------------------------
  def build_carton_template
  
   #target market and erp calculated fg_code
   begin
    carton_template = nil
    if self.carton_setup.carton_template != nil
      carton_template = self.carton_setup.carton_template
    else
      carton_template = CartonTemplate.new
    end
    
    if !self.carton_setup.carton_setup_update_timestamp
       self.carton_setup.update_time
    end
     
    carton_template.last_update_date_time = self.carton_setup.carton_setup_update_timestamp.last_update_timestamp
    
    carton_template.sell_by_code = self.retailer_sell_by_code
    carton_template.iso_week_code = self.carton_setup.production_schedule.iso_week_code
    carton_template.commodity_code  = self.carton_setup.retail_item_setup.item_pack_product.commodity_code
    carton_template.carton_mark_code = self.carton_setup.trade_unit_setup.mark_code
    carton_template.cpc_tu_mass = self.carton_setup.trade_unit_setup.carton_pack_product.nett_mass #new field as per feb'16 request
    target_market = TargetMarket.find_by_target_market_name(self.target_market)
    carton_template.target_market_code = target_market.target_market_name + "_" + target_market.target_market_description
    @marketing_variety_description = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(self.carton_setup.marketing_variety_code,@rmt_setup.commodity_code).marketing_variety_description.to_s
    carton_template.variety_short_long = self.carton_setup.marketing_variety_code + "_" + @marketing_variety_description
                    
    carton_template.inspection_type_code = self.carton_setup.pallet_setup.inspection_type_code
    carton_template.carton_label_code = self.carton_setup.trade_unit_setup.standard_label_code
    carton_template.order_number = self.carton_setup.order_number
    actual_count_code = actual_count_code = self.carton_setup.retail_item_setup.item_pack_product.actual_count.to_s
    if !(self.carton_setup.retail_item_setup.item_pack_product.size_ref == "NOS"||self.carton_setup.retail_item_setup.item_pack_product.size_ref == nil)
      actual_count_code = self.carton_setup.retail_item_setup.item_pack_product.size_ref
    end
    carton_template.actual_size_count_code = actual_count_code
    carton_template.grade_code = self.carton_setup.grade_code
    #question
    carton_template.old_pack_code = self.carton_setup.trade_unit_setup.old_pack_code.to_s
    carton_template.treatment_code = self.carton_setup.retail_item_setup.item_pack_product.treatment_code
     carton_template.treatment_type_code = self.carton_setup.retail_item_setup.item_pack_product.treatment_type_code
    carton_template.class_code = self.carton_setup.retail_item_setup.item_pack_product.product_class_code
    carton_template.pc_code = "PC" + @rmt_setup.rmt_product.ripe_point.pc_code.pc_code + "_" + @rmt_setup.rmt_product.ripe_point.pc_code.pc_name
    carton_template.pc_code_num = @rmt_setup.rmt_product.ripe_point.pc_code.pc_code 
    carton_template.track_indicator_code = @rmt_setup.output_track_indicator_code
    carton_template.cold_store_code = @rmt_setup.cold_store_code
    input_variety = RmtVariety.find_by_rmt_variety_code_and_commodity_code(@rmt_setup.variety_code,@rmt_setup.commodity_code) 
    
    carton_template.erp_cultivar = input_variety.rmt_variety_code + "_" + input_variety.rmt_variety_description.to_s
    
    inventory = InventoryCode.find_by_inventory_code(self.inventory_code)
    carton_template.inventory_code = self.inventory_code + "_" + inventory.inventory_name
    carton_template.spray_program_code = @rmt_setup.treatment_code
    
    carton_template.quantity = 1
    #------------------------------------------------------------------
    #Calculation:
    #iso_week of current day(must be 2 chars: i.e '1' = '01' + weekday(1-7) + numeric value of pc_code + rightmost char of isoweek(i.e. '1' if '01' or '5' if '15')
    #-------------------------------------------------------------------
    carton_template.pick_reference = nil #can only be calculated at mw exec time

    carton_template.remarks = self.remarks
    carton_template.organization_code = self.carton_setup.org
    #------------------------------------------------------------------
    #Calculation:
    #iso_week of current day 
    #NB can only be calculated at mw exec time
    #-------------------------------------------------------------------
    #carton_template.iso_week_code = self.carton_setup.production_schedule.iso_week_code
    season = Season.find_by_season_code(self.carton_setup.production_schedule.season_code)
    carton_template.season_code = season.season
    carton_template.fg_product_code = self.fg_product_code
    @brand_code = Mark.find_by_mark_code(self.carton_setup.trade_unit_setup.mark_code).brand_code
    carton_template.fg_code_old = self.carton_setup.commodity_code + " " + self.carton_setup.marketing_variety_code + " " + @brand_code + " " + self.carton_setup.trade_unit_setup.old_pack_code.to_s + " " + carton_template.actual_size_count_code
    carton_template.carton_setup = self.carton_setup
      
   
     @extended_fg_record = ExtendedFg.find_by_extended_fg_code(self.extended_fg_code)
     raise "No extended fg record exists with code: " + self.extended_fg_code.to_s + " for  carton setup: " + self.carton_setup.carton_setup_code if !@extended_fg_record
     carton_template.carton_fruit_nett_mass = @extended_fg_record.tu_nett_mass
     carton_template.extended_fg_code = @extended_fg_record.extended_fg_code
     carton_template.fg_mark_code = self.fg_mark_code
     carton_template.items_per_unit = self.carton_setup.retail_unit_setup.items_per_unit
     carton_template.units_per_carton = self.carton_setup.retail_unit_setup.units_per_carton
     
    carton_template.save
    @carton_template = carton_template                
   rescue
    raise "Method 'build_carton_template' failed. Exception reported: <br>: " + $!
   end
  end
  
   
   def set_label_values_for_run(run,label_setup)
     gtin_readable = run.batch_code
     if label_setup.gtin && label_setup.gtin.strip() != "" &&   run.batch_code
       label_setup.gtin_readable ="^01" + label_setup.gtin + "10" +  run.batch_code
     end
     print_count = false
     ru_type = self.carton_setup.retail_unit_setup.unit_pack_product.type_code
     label_setup.print_count = (ru_type == "T")
     label_setup.batch_code = run.batch_code
     iso_week = Date.today.cweek.to_s
     iso_week = "0" + iso_week if iso_week.length() == 1
     day = Time.now.wday.to_s
     day = "7" if day == "0"
     label_setup.pc_code = run.line_code if label_setup.pc_code_num == "-1"
     label_setup.pick_ref = iso_week.slice(1,1) + day + label_setup.pc_code + iso_week.slice(0,1)
     fpa = FarmPucAcount.get_account_for_farm_and_marketer(run.farm_code,label_setup.organization_code)
     puc = Puc.find_by_puc_code(fpa.puc_code)
     label_setup.puc_code = puc.puc_code
     label_setup.egap = puc.eurogap_code
     label_setup.phc = run.line.line_phc
     label_setup.nature_choice_certificate = puc.nature_choice_certificate_code if puc.nature_choice_certificate_code
     
   end
  
 
  
  def get_gtin
    
    #class_code = self.carton_setup.product_class_code
    old_pack = self.carton_setup.trade_unit_setup.old_pack_code
    self.org = self.carton_setup.org
    @rmt_setup = RmtSetup.find_by_production_schedule_name(self.production_schedule_code)
    commodity = @rmt_setup.commodity_code
    grade_code = self.carton_setup.grade_code
    
    std_count  = StandardSizeCount.find_by_standard_size_count_value_and_commodity_code_and_basic_pack_code(self.carton_setup.standard_size_count_value,commodity,self.carton_setup.retail_item_setup.basic_pack_code)
    trade_unit = self.carton_setup.trade_unit_setup
    mark = ""
    brand = ""
    if trade_unit
      mark = trade_unit.mark_code
      brand = Mark.find_by_mark_code(mark).brand_code.to_s if Mark.find_by_mark_code(mark)
      
    end
    
    actual_count = std_count.actual_count.to_s
    ipc = self.carton_setup.retail_item_setup.item_pack_product
    actual_count = ipc.size_ref if ipc.size_ref && ipc.size_ref.upcase != "NOS"
    
    variety = self.carton_setup.marketing_variety_code
    #should use old pack - new field
    query = "SELECT 
            public.gtins.gtin_code
            FROM
            public.gtins
            WHERE
            (now() < public.gtins.date_to and now() > public.gtins.date_from)AND
            (public.gtins.organization_code = '#{self.org}') AND 
            (public.gtins.commodity_code = '#{commodity}') AND 
            (public.gtins.marketing_variety_code = '#{variety}') AND 
            (public.gtins.old_pack_code = '#{old_pack}') AND 
            (public.gtins.brand_code = '#{brand}') AND 
            (public.gtins.actual_count = '#{actual_count}') AND 
            (public.gtins.grade_code = '#{self.carton_setup.grade_code}' AND 
            (public.gtins.inventory_code = '#{self.inventory_code}'))"
  
     puts "GTIN QUERY: " + query
     gtin = Gtin.find_by_sql(query).map{|g|g.gtin_code}[0]
     return gtin.to_s
    
 
end
  
end
