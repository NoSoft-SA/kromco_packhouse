class RwActivePallet < ActiveRecord::Base
  
  belongs_to :rw_receipt_pallet 
  has_many :rw_active_cartons,:order => "carton_number"
  belongs_to :production_run
  belongs_to :pallet
  belongs_to :rw_run
  
  attr_accessor  :target_market_short,:inventory_code_short,:production_run_code,:cpp_details


  def get_carton_count
        @carton_quantity_actual = self.connection.select_one("select count(*) from rw_active_cartons where pallet_number = '#{self.pallet_number}'")['count'].to_i
        return @carton_quantity_actual
   end

  def decompose_fields
    
    #target_market
    tm_vals = self.target_market_code.split("_")
    self.target_market_short = tm_vals[0]
    
    #inventory_code
    
    inv_vals = self.inventory_code.split("_")
    self.inventory_code_short = inv_vals[0]
    
  
  end


   def get_oldest_carton_cpp

     query = "SELECT
              carton_pack_products.carton_pack_product_code
            FROM
              public.extended_fgs,
              public.fg_products,
              public.carton_pack_products,
              public.rw_active_cartons
            WHERE
              extended_fgs.fg_code = fg_products.fg_product_code AND
              fg_products.carton_pack_product_code = carton_pack_products.carton_pack_product_code AND
              rw_active_cartons.extended_fg_code = extended_fgs.extended_fg_code AND
              rw_active_cartons.carton_number =
                (select rw_active_cartons.carton_number from rw_active_cartons where rw_active_cartons.pallet_number = '#{self.pallet_number}' order by id asc limit 1)"


        return self.connection.select_one(query)['carton_pack_product_code']



   end


    #------------------------------------------------------------------------------------------------------------
    #This method will group all cartons in the run by unique combinations of fields that form groups with
    #other fields. From each group a representative carton will be used to derive fields from this pallet's
    #changed(new) data. If fields could be derived without errors, all the cartons in the group will be updated
    #with a single bulk update statement- with the data of the representative carton
    #-------------------------------------------------------------------------------------------------------------
    def generic_bulk_carton_update(params)
    #-------------------------------------------------------------------------------
    #Find a unique list of all combinations of carton data that are dependent on other
    #data on same carton: e.g class,grade,size_count_code are dependent on each other
    #for a given combination must exist in the form as a fg_product_code. If we have
    #such a unique list, we can update each group as a whole, because each item
    #in the group will derive the exact same values as the group representative cartons
    #fields are: extended_fg_code,org_code,target_market_code,inventory_code,production_run_code
    #             inspection_type_code,sell_by_code
    #--------------------------------------------------------------------------------
    carton_group_defs = RwActiveCarton.find_by_sql("select distinct sell_by_code, extended_fg_code,organization_code,target_market_code,inventory_code,production_run_code,
               inspection_type_code, track_indicator_code, erp_cultivar,farm_code,puc from rw_active_cartons where
                        (rw_run_id = #{self.rw_run_id})")
     
     
     errs = ""
     representative_cartons = Array.new
     
     carton_group_defs.each do |group_def|
       carton = RwActiveCarton.find_all_by_extended_fg_code_and_farm_code_and_puc_and_organization_code_and_target_market_code_and_inventory_code_and_production_run_code_and_inspection_type_code_and_sell_by_code_and_track_indicator_code_and_erp_cultivar(group_def.extended_fg_code,group_def.farm_code,group_def.puc,group_def.organization_code,group_def.target_market_code,group_def.inventory_code,group_def.production_run_code,group_def.inspection_type_code,group_def.sell_by_code,
                                       group_def.track_indicator_code,group_def.erp_cultivar)[0]
       representative_cartons.push(carton)
     end                  
            
     #---------------------------------------------------------------------------------------------
     #Call update_from_pallet for each carton. Derived fields will be calculated in
     #this method and the 'derive_fields' method called within that method. Collect errors
     #returned by all representative cartons and raise exception. If no errors are returned, build
     #an update_all statement for each representative carton and execute. Raise exception if any
     #update statement failed
     # ---------------------------------------------------------------------------------------------
     puts "GROUPS: " + representative_cartons.length().to_s
     cartons_updated = 0
     representative_cartons.each do |repr_carton|
      # begin
         old_vals = {:extended_fg_code => repr_carton.extended_fg_code,:organization_code => repr_carton.organization_code,:target_market_code => repr_carton.target_market_code,:inventory_code => repr_carton.inventory_code,:inspection_type_code => repr_carton.inspection_type_code,:production_run_code => repr_carton.production_run_code,:sell_by_code => repr_carton.sell_by_code,
                     :erp_cultivar => repr_carton.erp_cultivar,:track_indicator_code => repr_carton.track_indicator_code,:farm_code => repr_carton.farm_code,:puc => repr_carton.puc}
         
         errs = repr_carton.update_from_pallet(params)
         raise errs if errs != ""
         cartons_updated += update_group(repr_carton,old_vals)
         puts "group updated"
      #rescue
      #  raise "Group update from representative carton: " + repr_carton.carton_number.to_s + " failed. Reason:<BR>" + $!
     # end
     end
     
     raise "No cartons were updated" if cartons_updated == 0
     return cartons_updated
    
    end
  
     def set_oldest_pack_date_time

       query = " select pack_date_time, pick_reference from rw_active_cartons where rw_active_pallet_id = #{self.id} order by pack_date_time asc limit 1"
       rec =     self.connection.select_one(query)

      return if !rec

       self.oldest_pack_date_time =rec['pack_date_time'].to_datetime
       self.pick_reference_code =    rec['pick_reference']



     end

    def update_group(carton,old_vals)
     carton.reworks_action = "reclassified" if carton.reworks_action.upcase != "ALT_PACKED"
     carton.items_per_unit = 0 if !carton.items_per_unit
     carton.units_per_carton = 0 if !carton.units_per_carton
     
      set_str = "commodity_code = $$#{carton.commodity_code}$$,
                carton_mark_code = $$#{carton.carton_mark_code}$$,
                target_market_code = $$#{carton.target_market_code}$$,
                variety_short_long = $$#{carton.variety_short_long}$$,
                fg_code_old = $$#{carton.fg_code_old}$$,
                inspection_type_code = $$#{carton.inspection_type_code}$$,
                actual_size_count_code = $$#{carton.actual_size_count_code}$$,
                grade_code = $$#{carton.grade_code}$$,
                old_pack_code = $$#{carton.old_pack_code}$$,
                treatment_code = $$#{carton.treatment_code}$$,
                product_class_code = $$#{carton.product_class_code}$$,
                erp_cultivar = $$#{carton.erp_cultivar}$$,
                pc_code = $$#{carton.pc_code}$$,
                inventory_code = $$#{carton.inventory_code}$$,
                farm_code = $$#{carton.farm_code}$$,
                carton_fruit_nett_mass = $$#{carton.carton_fruit_nett_mass}$$,
                pick_reference = $$#{carton.pick_reference}$$,
                line_code = $$#{carton.line_code}$$,
                shift_code = $$#{carton.shift_code}$$,
                organization_code = $$#{carton.organization_code}$$,
                puc = $$#{carton.puc}$$,
                fg_product_code = $$#{carton.fg_product_code}$$,
                production_run_code = $$#{carton.production_run_code}$$,
                production_run_id = $$#{carton.production_run_id}$$,
                account_code = $$#{carton.account_code}$$,
                egap = $$#{carton.egap}$$,
                sell_by_code = $$#{carton.sell_by_code}$$,
                items_per_unit = #{carton.items_per_unit.to_s},
                units_per_carton = #{carton.units_per_carton.to_s},
                fg_mark_code = $$#{carton.fg_mark_code}$$,
                extended_fg_code = $$#{carton.extended_fg_code}$$,
                reworks_action = '#{carton.reworks_action}',
                rw_receipt_unit = 'pallet'"
                
     return  RwActiveCarton.update_all(ActiveRecord::Base.extend_set_sql_with_request(set_str,"rw_active_cartons"),"rw_run_id = #{self.rw_run_id} AND sell_by_code = $$#{old_vals[:sell_by_code]}$$ AND extended_fg_code = $$#{old_vals[:extended_fg_code]}$$ AND
                               organization_code = $$#{old_vals[:organization_code]}$$ AND target_market_code = $$#{old_vals[:target_market_code]}$$ AND
                               inventory_code = $$#{old_vals[:inventory_code]}$$ AND production_run_code = $$#{old_vals[:production_run_code]}$$ AND
                               track_indicator_code = $$#{old_vals[:track_indicator_code]}$$ AND
                               erp_cultivar = $$#{old_vals[:erp_cultivar]}$$  AND
                               farm_code = $$#{old_vals[:farm_code]}$$ and puc = $$#{old_vals[:puc]}$$ and
                               inspection_type_code = '#{old_vals[:inspection_type_code]}' AND rw_active_pallet_id is not null AND rw_receipt_unit = 'pallet'")
    end
  
  
  
  
  
  
  
  
  
  
  def update_all_target_market
   
   RwActiveCarton.update_all(ActiveRecord::Base.extend_set_sql_with_request("target_market_code ='#{self.target_market_code}',reworks_action = 'reclassified'","rw_active_cartons"),"rw_run_id =#{self.rw_run_id.to_s}")
   RwActivePallet.update_all(ActiveRecord::Base.extend_set_sql_with_request("target_market_code ='#{self.target_market_code}',reworks_action = 'reclassified'","rw_active_pallets"),"rw_run_id =#{self.rw_run_id.to_s}")
  
  end
  #-------------------------------------------------
  #This method takes the current target market value
  #on the pallet and check whether a bulk update can
  #be applied to all cartons and all pallets in the
  #reworks run. It builds a list of all error cases
  #--------------------------------------------------
  def check_target_market_validity_for_bulk_update
   #------------
   #pallet check
   #------------
   err_list = Array.new
   pallet_orgs = self.connection.select_all("select distinct organization_code from rw_active_pallets where rw_run_id = #{self.rw_run_id.to_s}")
   pallet_orgs.each do |pallet_org|
    if !TargetMarket.is_valid_for_org?(pallet_org["organization_code"],self.target_market_short)
     err_list.push(["pallets",pallet_org["organization_code"],self.target_market_short])
    end
   end
   
   carton_orgs = self.connection.select_all("select distinct organization_code from rw_active_cartons where rw_run_id = #{self.rw_run_id.to_s}")
   carton_orgs.each do |carton_org|
    if !TargetMarket.is_valid_for_org?(carton_org["organization_code"],self.target_market_short)
     err_list.push(["cartons",carton_org["organization_code"],self.target_market_short])
    end
   end
   
    return err_list
    
  end
  
  
  
  def proccess_virtual_fields
     if self.inventory_code_short && self.inventory_code_short != ""
        inventory = InventoryCode.find_by_inventory_code(self.inventory_code_short)
        self.inventory_code = self.inventory_code_short + "_" + inventory.inventory_name
     end
   
     if self.target_market_short && self.target_market_short != ""
       target_market = TargetMarket.find_by_target_market_name(self.target_market_short)
       self.target_market_code = target_market.target_market_name + "_" + target_market.target_market_description
     end
  
  end
  
  def derive_fields()
  
   msg = ""
   
   
   if self.inventory_code_short && self.inventory_code_short != ""
    inventory = InventoryCode.find_by_inventory_code(self.inventory_code_short)
    self.inventory_code = self.inventory_code_short + "_" + inventory.inventory_name
   end
   
   if self.target_market_short && self.target_market_short != ""
     target_market = TargetMarket.find_by_target_market_name(self.target_market_short)
     self.target_market_code = target_market.target_market_name + "_" + target_market.target_market_description
   end

   fg_code = self.fg_product_code
   
   
   if self.changed_fields.has_key?('class_code')
    old_class_code = self.changed_fields['class_code'][0]
    puts old_class_code
    fg_code.gsub!("_" + old_class_code + "_", "_" + self.class_code + "_")
   end 
   
  
   if self.changed_fields.has_key?('grade_code')
    old_grade_code = self.changed_fields['grade_code'][0]
    fg_code.gsub!("_" + old_grade_code + "_", "_" + self.grade_code + "_")
   end 
   
    
   if !FgProduct.find_by_fg_product_code(fg_code)
     return "FG code: " + fg_code + " does not exist!"
   else
     self.fg_product_code = fg_code
   end
    
   #-----------------------------------------------------------------
   #old fg code: This works, since class and grade cannot be changed
   #-----------------------------------------------------------------
   @brand_code = Mark.find_by_mark_code(self.carton_mark_code).brand_code
   
    self.pallet_format_product_id = PalletFormatProduct.find_by_pallet_format_product_code(self.pallet_format_product_code).id
   
   self.fg_code_old = self.commodity_code + " " + self.marketing_variety_code + " " + @brand_code + " " + self.old_pack_code.to_s + " " + self.actual_size_count_code
   
   return ""
   
  end


  def before_update
    i = 1
  end


  def before_save
    i = 1
  end


  def set_account(is_reworks = true)


      cartons_table = "rw_active_cartons"


    query = " SELECT
       count(  distinct (#{cartons_table}.account_code)),pallet_number ,max (#{cartons_table}.account_code)as account_code
       FROM
       #{cartons_table}
       where
       pallet_number= '#{self.pallet_number}'
       group by pallet_number"


    result = ActiveRecord::Base.connection.select_one(query)
    if result['count'].to_i > 1
      self.account_code = '6512'
    else
      self.account_code = result['account_code']
    end

    return self.account_code


 end
  
 
  def RwActivePallet.calc_check_digit(num)
   
   sum = 0
   
    for i in 0..num.length() -1
	n = num[i..i].to_i
	pos = i +1
        if pos%2 != 0
		sum += (n*3)
	else
		sum += (n*1)
		
	end
	
    end
   
    remainder = sum%10
    if remainder == 0
      return remainder.to_s
    else
      return (10 - remainder).to_s
    end

  end
  
  def scrap(reason,user)
    
    self.transaction do
      self.carton_quantity_actual = 0
      scrap_pallet = RwScrapPallet.new
      self.rw_receipt_pallet.export_attributes(scrap_pallet,true) if self.rw_receipt_pallet
      scrap_pallet.rw_reason_id = reason.id
      now = Time.now
      scrap_pallet.rw_scrap_datetime = now
      scrap_pallet.user_name = user.user_name
      scrap_pallet.person = user.person.last_name + "," + user.person.first_name
      scrap_pallet.rw_receipt_pallet = self.rw_receipt_pallet
      scrap_pallet.create
      #deref the rw_active_pallet_id on all active cartons
      self.rw_active_cartons.each do |carton|
         carton.rw_active_pallet = nil
         carton.pallet_id = nil
         carton.pallet_number = nil
         carton.rw_receipt_unit = "carton"
         carton.rw_pallet_action = "pallet_scrapped"
         carton.update
      end
      
      self.destroy
      
  end
  
  end
  
  
  def after_find
  
   self.carton_quantity_actual = self.rw_active_cartons.length
     if !self.actual_size_count_code
         ipc = FgProduct.find_by_fg_product_code(self.fg_product_code).item_pack_product
         actual_count = ipc.actual_count.to_s
         actual_count = ipc.size_ref if ipc.size_ref && ipc.size_ref.upcase != "NOS"
         self.actual_size_count_code = actual_count     
        
      end
  end
  
  def scrap_cartons(reason,user)
    
    self.transaction do
      self.carton_quantity_actual = 0
      scrap_pallet = RwScrapPallet.new
      self.rw_receipt_pallet.export_attributes(scrap_pallet,true) if self.rw_receipt_pallet
      scrap_pallet.rw_reason_id = reason.id
      now = Time.now
      scrap_pallet.rw_scrap_datetime = now
      scrap_pallet.user_name = user.user_name
      scrap_pallet.person = user.person.last_name + "," + user.person.first_name
      scrap_pallet.rw_receipt_pallet = self.rw_receipt_pallet
      scrap_pallet.create
      #deref the rw_active_pallet_id on all active cartons
      self.rw_active_cartons.each do |carton|
         scrap_carton = RwScrapCarton.new
         carton.rw_receipt_carton.export_attributes(scrap_carton,true)
         scrap_carton.rw_reason_id = reason.id
         scrap_carton.user_name = user.user_name
         now = Time.now
        scrap_carton.rw_scrap_datetime = now
        scrap_carton.person = user.person.last_name + "," + user.person.first_name
        scrap_carton.rw_receipt_carton = carton.rw_receipt_carton
        scrap_carton.create
        carton.destroy
      end
      
      self.destroy
      
  end
  
  end
  
end
