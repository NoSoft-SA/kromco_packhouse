class RetailItemSetup < ActiveRecord::Base

  belongs_to :handling_product
  belongs_to :product #pack material
  belongs_to :carton_setup
  
  belongs_to :item_pack_product
  
  attr_reader :production_schedule_code,:org,:color_percentage,:grade_code,:std_count,
              :sequence_number,:order_number,:ignore_item_product_create,:act_count
              
  attr_writer :production_schedule_code,:org,:color_percentage,:grade_code,:std_count,
              :sequence_number,:order_number,:ignore_item_product_create,:act_count
              
  
  def production_schedule_code
    
    if @production_schedule_code == nil
      @production_schedule_code = self.carton_setup.production_schedule_code
    end
    
    return @production_schedule_code
  end
    
  #----------------------------------------------------------------------
  #Item pack product must be found by following fields:
  #-> commodity_code :rmt_setup
  #-> marketing_variety :carton_setup
  #->actual count: convert std count from carton setup to actual using table:
  #  (with commodity as key)
  #->class: carton_setup
  #->grade: carton setup
  #-> cosmetic_code: is calculated: fruit_sticker_code (or if blank, use 'blank' +
  #                 '_' + treatment_code (or if blank, use 'blank'
  #                
  #if a IPC with above composite ey can not be found create it and ref the
  #created IPC
  #----------------------------------------------------------------------
  
  
  
  def create_item_pack_product_code
     puts "IN RETAIL CREATE IPC"
    cosmetic_code = ""
     if self.label_code == "U" 
        if self.carton_setup.treatment_code == "U"
          cosmetic_code = "UL"
        else
          cosmetic_code = "WX"
        end
     else
         if self.carton_setup.treatment_code == "U"
          cosmetic_code = "LB"
        else
          cosmetic_code = "LW"
        end
     
     end
     
    
    class_code = self.carton_setup.product_class_code
    puts "prod sched: " + self.production_schedule_code
    commodity = RmtSetup.find_by_production_schedule_name(self.production_schedule_code).commodity_code
    grade_code = self.carton_setup.grade_code
   
    std_count  = StandardSizeCount.find_by_standard_size_count_value_and_commodity_code_and_basic_pack_code(self.carton_setup.standard_size_count_value,commodity,self.basic_pack_code)
    
    if !std_count
     err = "An IPC could not be found or created, because no standard_size_count record exists for the following field values: <br>"
     err += "standard_size_count_value: " + self.carton_setup.standard_size_count_value.to_s + "<br>"
     err += "commodity: " + commodity + "<br>"
     err += "basic_pack_code: " + self.basic_pack_code
     raise err
     
    end
    actual_count = std_count.actual_count
    
    variety = self.carton_setup.marketing_variety_code
    
    item_pack = ItemPackProduct.find_by_product_class_code_and_commodity_code_and_grade_code_and_actual_count_and_marketing_variety_code_and_cosmetic_code_name_and_size_ref_and_basic_pack_code(class_code,commodity,grade_code,actual_count,variety,cosmetic_code,self.size_ref,self.basic_pack_code)
 
    if ! item_pack
      
      item_pack = ItemPackProduct.new
      item_pack.product_class_code = class_code
      item_pack.commodity_code = commodity
      item_pack.commodity_group_code = std_count.commodity.commodity_group_code
      item_pack.cosmetic_code_name = cosmetic_code
      item_pack.grade_code = grade_code
      item_pack.basic_pack_code = self.basic_pack_code
      
      item_pack.treatment_code = self.carton_setup.treatment_code
      item_pack.treatment = Treatment.find_by_treatment_code_and_treatment_type_code(item_pack.treatment_code,"PACKHOUSE")
      item_pack.grade = Grade.find_by_grade_code(grade_code)
      item_pack.standard_size_count = std_count
      item_pack.standard_size_count_value = std_count.standard_size_count_value
      item_pack.marketing_variety_code = variety
      item_pack.actual_count = actual_count
      item_pack.size_ref = self.size_ref
      puts item_pack.size_ref
      item_pack.create
      
      
    end
    
    
    if ! self.new_record?
     old_ri = RetailItemSetup.find(self.id)
     old_ipc = old_ri.item_pack_product_code 
     old_mark = old_ri.mark_code
    end
    
    self.item_pack_product = item_pack
    
    
    self.item_pack_product_code = item_pack.item_pack_product_code
    
    if ! self.new_record? && self.carton_setup.fg_setup
      
      if old_ipc !=  self.item_pack_product_code||old_mark != self.mark_code
       @update_fg = true
      end
    end
      
   end
   
 def after_save
  if @update_fg
    self.carton_setup.fg_setup.new_ipc = self.item_pack_product_code
    self.carton_setup.fg_setup.production_schedule_code = self.production_schedule_code
    self.carton_setup.fg_setup.save
  end
  
   self.carton_setup.update_time
 
 end
  
  def after_create
  
   self.carton_setup.update_time
  end
  
  def validate 
 
    is_valid = true	
	#if is_valid
		 ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code}],self,true) 
	#end
	#now check whether fk combos combine to form valid foreign keys
	 if self.pack_material_product_code
		 is_valid = set_pack_material_product
	 else
	  self.product = nil
	 end
	# if is_valid
		 ModelHelper::Validations.validate_combos([{:handling_product_code => self.handling_product_code}],self,true) 
	# end
	#n#ow check whether fk combos combine to form valid foreign keys
	 if self.handling_product_code
		 is_valid = set_handling_product
	 else
	   self.handling_message = nil
	   self.handling_product = nil
	 end
	 
    if is_valid
		is_valid = ModelHelper::Validations.validate_combos([{:basic_pack_code => self.basic_pack_code}],self) 
	end
	
	if is_valid && !self.ignore_item_product_create
	   create_item_pack_product_code
	end
	 
end

#	===========================
#	 foreign key validations:
#	===========================
def set_pack_material_product

	pack_material_product = Product.find_by_product_code(self.pack_material_product_code)
	 if pack_material_product != nil 
		 self.product = pack_material_product
		 return true
	 else
		errors.add_to_base("'pack_material_product_code' is invalid: not found in database")
		 return false
	end
end
 
 
def set_handling_product
   
	handling_product = HandlingProduct.find_by_handling_product_code(self.handling_product_code)
	 if handling_product != nil 
		 self.handling_product = handling_product
		 self.handling_message = handling_product.handling_message
		 return true
	 else
		errors.add_to_base("'handling_product_code'  is invalid")
		 return false
	end
end
 
 
 
end
