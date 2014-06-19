class ProcessingSetup < ActiveRecord::Base 
	
	attr_writer :commodity_code,:trade_env_code
	attr_reader :commodity_code,:trade_env_code
	
#	===========================
# 	Association declarations:
#	===========================
    
 
	belongs_to :pack_material_product
	belongs_to :grade
	belongs_to :handling_product
	belongs_to :treatment
	belongs_to :product_class
	belongs_to :production_schedule
 
#	============================
#	 Validations declarations:
#	============================
	
	validates_presence_of :variety_output_description

	
	
	
#	validates_numericality_of :standard_size_count_from
#	validates_numericality_of :standard_size_count_to
	
	
	def validate
	  if !self.color_percentage
	   self.color_percentage = -1
	  end
	end
	
	
	def before_create
	 
	end
	
	def ProcessingSetup.smallest_std_count_for_pack(schedule)
       query = "SELECT min(processing_setups.standard_size_count_to)as minval
           FROM
           public.processing_setups where 
           (public.processing_setups.production_schedule_code = '#{schedule}' AND
           public.processing_setups.handling_product_type_code = 'PACK')"
            
       val = connection.select_one(query)
       if val["minval"]== nil
         return 0
       else
         return val["minval"].to_i 
       end
  
    end
    
    def ProcessingSetup.biggest_std_count_for_pack(schedule)
       query = "SELECT max(processing_setups.standard_size_count_from)as maxval
           FROM
           public.processing_setups where 
           (public.processing_setups.production_schedule_code = '#{schedule}'AND
           public.processing_setups.handling_product_type_code = 'PACK')"
            
       val = connection.select_one(query)
       if val["maxval"]== nil
         return 0
       else
         return val["maxval"].to_i 
       end
  
    end
	

	def before_save
	  begin
	  
	  self.commodity_code = self.production_schedule.rmt_setup.commodity_code
	  
	  if self.handling_product.handling_product_type_code.upcase == "REBIN"
	     self.pack_material_type_code = "RMU"
	     self.pack_material_sub_type_code = "BIN"
	     
	     if self.new_record?
	       rebin_setup =RebinSetup.new
	       rebin_setup.auto_created = true
	       #-------------------------------------------------------------
	       #Jan 09 change: ripe point now comes from schedule's rmt setup
	       #-------------------------------------------------------------
	       rebin_setup.ripe_point_code = self.production_schedule.rmt_setup.ripe_point_code
	       rebin_setup.product_code_pm_bintype = self.pack_material_product_code
	       export_attributes(rebin_setup)
	       rebin_setup.production_schedule = self.production_schedule
	       rebin_setup.create
	     else
	      if self.standard_size_count_from != -1 && standard_size_count_to != -1
	       #old_record_state = ProcessingSetup.find(self.id)
	       rebins = all_rebins_in_range
	       if rebins.length > 0
	       rebins.each do |rebin_setup| 
	       #rebin_setup = RebinSetup.find_by_production_schedule_id_and_standard_size_count_from_and_standard_size_count_to(self.production_schedule_id,old_record_state.standard_size_count_from,old_record_state.standard_size_count_to)
	         rebin_setup.product_code_pm_bintype = self.pack_material_product_code
	         export_attributes(rebin_setup,nil,["standard_size_count_from","standard_size_count_to"])if rebin_setup
	         rebin_setup.update if rebin_setup
	       end
	      end
	      end
	     end
	  elsif self.handling_product.handling_product_type_code.upcase == "PACK"
	     self.pack_material_type_code = "LB"
	     self.pack_material_sub_type_code = "FRUIT"
	    #---------------------------------------------------------------------------------------------
	    #find all the standard_size_count_records that fit into the selected size-count from-to range
	    #For each record, create a carton setup record
	    #---------------------------------------------------------------------------------------------
	    if self.new_record?
	    
	      counts = StandardSizeCount.find_by_sql("Select distinct standard_size_count_value from standard_size_counts where (
	                      commodity_code = '#{self.commodity_code}' and standard_size_count_value >= '#{self.standard_size_count_to}' and
	                      standard_size_count_value <= '#{self.standard_size_count_from}')").map {|c|c.standard_size_count_value}
	                      
	                       
	       counts.each do |count|
	         #Only create a new record if such a count with current grain does not exist: It can exist
	         #because of the way the user inputs ranges: i.e. 40 to 30 will give counts 40 and 30,
	         #                                                30 to 20 will give counts 30 and 20
	         #                                                SO 30 has already been created
	         #                                                 
	         carton_setup = CartonSetup.new 
	         if !CartonSetup.find_by_production_schedule_code_and_color_percentage_and_grade_code_and_standard_size_count_value_and_trade_env_code(self.production_schedule_code,self.color_percentage,self.grade_code,count,self.trade_env_code)
	           carton_setup.color_percentage = self.color_percentage
	           trade_env = TradeEnvironmentSetup.find_by_production_schedule_code_and_trade_env_code(self.production_schedule_code,self.trade_env_code)
	           carton_setup.org = trade_env.organization_marketing
	           carton_setup.trade_env_code = trade_env.trade_env_code
	           carton_setup.product_class_code = self.product_class_code
	           carton_setup.grade_code = self.grade_code
	           carton_setup.fruit_sticker_code = self.pack_material_product_code
	           carton_setup.fruit_sticker_code = "U" if !self.pack_material_product_code
	           carton_setup.treatment_code = self.treatment_code
	           carton_setup.treatment_code = "U" if !self.treatment_code
	           carton_setup.marketing_variety_code = self.variety_output_description
	           carton_setup.sequence_number = 1
	           carton_setup.production_schedule_code = self.production_schedule_code
	           carton_setup.production_schedule = self.production_schedule
	           carton_setup.standard_size_count_value = count
	           carton_setup.commodity_code = self.commodity_code
	           carton_setup.treatment_type_code = self.treatment_type_code
	           carton_setup.create
	        end
	     
	       end                 
	    
	    else
	    
	      carton_setups = CartonSetup.get_all_in_range(self.production_schedule_id,self.standard_size_count_from,self.standard_size_count_to,self.color_percentage,self.grade_code)
	      carton_setups.each do |carton_setup|
	        carton_setup.color_percentage = self.color_percentage
	        carton_setup.grade_code = self.grade_code
	        carton_setup.fruit_sticker_code = self.pack_material_product_code
	        carton_setup.fruit_sticker_code = "U" if !self.pack_material_product_code
	         carton_setup.treatment_code = self.treatment_code
	         carton_setup.treatment_code = "U" if !self.treatment_code
	        carton_setup.product_class_code = self.product_class_code
	        carton_setup.marketing_variety_code = self.variety_output_description
	        carton_setup.update
	      
	      end
	    end
	  end
	  return true
	 rescue
	   puts "exception"
	   raise "Data related operations failed in 'before_save'. Reported exception is: <br>" + $!
	 end
	end
	
	def all_rebins_in_range
	 
	 condition = "production_schedule_id = '#{self.production_schedule_id}' and standard_size_count_from <= '#{self.standard_size_count_from}' and
	                        standard_size_count_to >= '#{self.standard_size_count_to}' and
	                        standard_size_count_to <= '#{self.standard_size_count_from}' and
	                        standard_size_count_from >= '#{self.standard_size_count_to}'and
	                        standard_size_count_from <> -1 and standard_size_count_to <> -1"
	                        
	 return RebinSetup.find(:all,:conditions => condition)
	
	
	end
	
	def before_destroy
	 if self.handling_product.handling_product_type_code.upcase == "REBIN"
	   RebinSetup.destroy_all("production_schedule_id = '#{self.production_schedule_id}' and standard_size_count_from <= '#{self.standard_size_count_from}' and
	                        standard_size_count_to >= '#{self.standard_size_count_to}' and
	                        standard_size_count_to <= '#{self.standard_size_count_from}' and
	                        standard_size_count_from >= '#{self.standard_size_count_to}'and
	                        standard_size_count_from <> -1 and standard_size_count_to <> -1 and
	                        color_percentage = '#{self.color_percentage}' and
	                        grade_code = '#{self.grade_code}'")
	                        
	 elsif self.handling_product.handling_product_type_code.upcase == "PACK"
	 
	   CartonSetup.destroy_all("production_schedule_id = '#{self.production_schedule_id}' and
	                      standard_size_count_value >= '#{self.standard_size_count_to}' and
	                      standard_size_count_value <= '#{self.standard_size_count_from}' and
	                      color_percentage = '#{self.color_percentage}' and
	                      grade_code = '#{self.grade_code}'")
	                      
	 end
	end
	
#	=====================
#	 Complex validations:
#	=====================

def range_modified?
 old_record_state = ProcessingSetup.find(self.id)
 if old_record_state.standard_size_count_from != self.standard_size_count_from ||
       old_record_state.standard_size_count_to != self.standard_size_count_to
      return true
 else
   return false
 end

end

def range_overlap
  
  return false if !self.new_record? && range_modified? == false
  #-------------------------------------------------------------------------------------
  #If it's an existing record,we only need to test for overlap if the range have been
  #modified
  #-------------------------------------------------------------------------------------
   query = " select id from processing_setups where (grade_code = '#{self.grade_code}' and color_percentage = '#{self.color_percentage}' and production_schedule_id = '#{self.production_schedule.id}' and handling_product_type_code = '#{self.handling_product_type_code}' and
  ((standard_size_count_from <= '#{self.standard_size_count_from}' and standard_size_count_to >= '#{self.standard_size_count_to}') or
  (standard_size_count_from >= '#{self.standard_size_count_from}' and standard_size_count_to >= '#{standard_size_count_to}' and standard_size_count_to <= '#{standard_size_count_to}') or
  (standard_size_count_from <= '#{standard_size_count_from}' and standard_size_count_to <= '#{standard_size_count_to}' and standard_size_count_from >= '#{standard_size_count_from}')))"

   if ProcessingSetup.find_by_sql(query).length() == 0
    return false
   else
    return true
   end
end


def validate 
     
     #-------------------------------------------------------------------------------------------
     #pack material can be blank, so the validate_combos method will only set the field values to
     #null if they contain the combo prompting text 'select a value from...'
     #-------------------------------------------------------------------------------------------
	 is_valid = true
	 
	 is_valid = ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code}],self,true) 
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pack_material_product
	 else
	  self.pack_material_type_code = nil
	  self.pack_material_sub_type_code = nil
	  self.pack_material_product_code = nil
	 end
	 
	 #-----------------------------------------------------------------------------------------------------------------
	  #We do not want the above section to invalidate the object here, only set values to nil if user provided no input
     #----------------------------------------------------------------------------------------------------------------
	 is_valid = true
	 
	 ModelHelper::Validations.validate_combos([{:grade_code => self.grade_code}],self,true) 
	
	#now check whether fk combos combine to form valid foreign keys
	 if self.grade_code
		 set_grade
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:product_class_code => self.product_class_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_product_class
	 end
	 if is_valid
	     
		 is_valid = ModelHelper::Validations.validate_combos([{:handling_product_code => self.handling_product_code}],self) 
	     if self.handling_product_code.upcase == "NONE"
	       errors.add(:handling_product_code,": You must select a handling product code (other than 'NONE')")
	       is_valid = false
	     end
	 end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_handling_product
	 end
	 if is_valid
		is_valid = ModelHelper::Validations.validate_combos([{:treatment_code => self.treatment_code}],self) 
	    
	 end
	#now check whether fk combos combine to form valid foreign keys
	 
     self.color_percentage = -1 if ! self.color_percentage
    
    if is_valid
      
      handling_product = HandlingProduct.find_by_handling_product_code(self.handling_product_code)
      type = handling_product.handling_product_type_code
      if type.upcase != "PACK" && type.upcase != "REBIN"
         self.errors.add("handling_product_code","The handling product's TYPE must be 'PACK' or 'REBIN")
      end
    end
    
    if is_valid
     if self.handling_product.handling_product_type_code.upcase == "PACK" # -1 is "all" choice in dropdown
      
      if self.standard_size_count_from == -1
        self.errors.add("standard_size_count_from","'all' can only be used for rebin handling types")
        
        is_valid = false
      end
      if self.standard_size_count_to == -1
        self.errors.add("standard_size_count_to","'all' can only be used for rebin handling types")
        is_valid = false
      end
     end 
     
     
     if self.treatment_code
		 is_valid = set_treatment
	 end
	 
    end
   
   
#   puts "is valid: " + is_valid.to_s
#   if self.handling_product.handling_product_type_code.upcase == "REBIN" 
#    if self.standard_size_count_from == -1 || self.standard_size_count_to == -1
#      puts "sscf1: " + self.standard_size_count_from.to_s
#      return is_valid
#    end
#   end
   

    if is_valid
      if self.standard_size_count_from < self.standard_size_count_to
       is_valid = false
       self.errors.add("standard_size_count_from","the value of 'standard_size_count_from' must be greater than <br> the value of 'standard_size_count_to'")
      end
    end
    
    
     if  is_valid 
      exists = range_overlap
      if exists
       puts "range overlap error"
       self.errors.add_to_base("You already have a processing record for this schedule for the selected size count range")
      end
     end
     
end

#	===========================
#	 foreign key validations:
#	===========================
def set_pack_material_product
  
	pack_material_product = PackMaterialProduct.find_by_pack_material_product_code(self.pack_material_product_code)
	 if pack_material_product != nil 
		 self.pack_material_product = pack_material_product
		 return true
	 else
		errors.add_to_base("pack_material_product_code not found in db")
		 return false
	end
end
 
def set_grade

	grade = Grade.find_by_grade_code(self.grade_code)
	 if grade != nil 
		 self.grade = grade
		 return true
	 else
		errors.add_to_base("value of field: 'grade_code' is invalid")
		 return false
	end
end
 
def set_handling_product

	handling_product = HandlingProduct.find_by_handling_product_code(self.handling_product_code)
	 if handling_product != nil 
		 self.handling_product = handling_product
		 self.handling_product_type_code = handling_product.handling_product_type_code
		 self.treatment_type_code = "PACKHOUSE"
		 return true
	 else
		errors.add_to_base("'handling_product_code is invalid'")
		 return false
	end
end
 
def set_treatment

	treatment = Treatment.find_by_treatment_code_and_treatment_type_code(self.treatment_code,self.treatment_type_code)
	 if treatment != nil 
		 self.treatment = treatment
		 return true
	 else
		errors.add_to_base("treatment_code' is invalid")
		 return false
	end
end
 
def set_product_class

	product_class = ProductClass.find_by_product_class_code(self.product_class_code)
	 if product_class != nil 
		 self.product_class = product_class
		 return true
	 else
		errors.add_to_base("product_class_code'  is invalid")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: pack_material_product_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_pack_material_type_codes

	pack_material_type_codes = PackMaterialProduct.find_by_sql('select distinct pack_material_type_code from pack_material_products where pack_material_type_code is not null').map{|g|[g.pack_material_type_code]}
end



def self.get_all_pack_material_sub_type_codes

	pack_material_sub_type_codes = PackMaterialProduct.find_by_sql('select distinct pack_material_sub_type_code from pack_material_products').map{|g|[g.pack_material_sub_type_code]}
end



def self.pack_material_sub_type_codes_for_pack_material_type_code(pack_material_type_code)

	pack_material_sub_type_codes = PackMaterialProduct.find_by_sql("Select distinct pack_material_sub_type_code from pack_material_products where pack_material_type_code = '#{pack_material_type_code}'").map{|g|[g.pack_material_sub_type_code]}

	pack_material_sub_type_codes.unshift("<empty>")
 end



def self.get_all_pack_material_product_codes

	pack_material_product_codes = PackMaterialProduct.find_by_sql('select distinct pack_material_product_code from pack_material_products').map{|g|[g.pack_material_product_code]}
end



def self.pack_material_product_codes_for_pack_material_sub_type_code_and_pack_material_type_code(pack_material_sub_type_code, pack_material_type_code)

	pack_material_product_codes = PackMaterialProduct.find_by_sql("Select distinct pack_material_product_code from pack_material_products where pack_material_sub_type_code = '#{pack_material_sub_type_code}' and pack_material_type_code = '#{pack_material_type_code}'").map{|g|[g.pack_material_product_code]}

	pack_material_product_codes.unshift("<empty>")
 end
 
 
 def self.pack_material_product_codes_for_pack_material_type_code(pack_material_type_code)

	pack_material_product_codes = PackMaterialProduct.find_by_sql("Select distinct pack_material_product_code from pack_material_products where pack_material_type_code = '#{pack_material_type_code}'").map{|g|[g.pack_material_product_code]}

	pack_material_product_codes.unshift("<empty>")
 end


#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: handling_product_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_handling_product_codes

	handling_product_codes = HandlingProduct.find_by_sql('select distinct handling_product_code from handling_products').map{|g|[g.handling_product_code]}
end


#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: treatment_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_treatment_codes

	treatment_codes = Treatment.find_by_sql('select distinct treatment_code from treatments').map{|g|[g.treatment_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: product_class_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_product_class_codes

	product_class_codes = ProductClass.find_by_sql('select distinct product_class_code from product_classes').map{|g|[g.product_class_code]}
end






end
