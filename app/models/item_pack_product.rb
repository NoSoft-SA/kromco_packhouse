class ItemPackProduct < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :grade
	belongs_to :marketing_variety
	belongs_to :product_class
	belongs_to :standard_size_count
	belongs_to :cosmetic_code
	belongs_to :treatment
	belongs_to :product
 
#	============================
#	 Validations declarations:
#	============================
	#validates_presence_of :item_pack_product_code
	validates_presence_of :treatment_code
	validates_presence_of :grade_code
	validates_presence_of :product_class_code
	validates_presence_of :marketing_variety_code
	validates_presence_of :cosmetic_code_name
	validates_presence_of :commodity_code
	
	
	
  def ItemPackProduct.get_all_for_commodity_and_rmt_variety(commodity,rmt_variety)
        query = "SELECT public.item_pack_products.*
            FROM
            public.item_pack_products
            INNER JOIN public.varieties ON (public.item_pack_products.marketing_variety_id = public.varieties.marketing_variety_id)
            WHERE
            (public.varieties.commodity_code = '#{commodity}') AND
          (public.varieties.rmt_variety_code = '#{rmt_variety}')"
  
       return ItemPackProduct.find_by_sql(query)
  end
	

def before_update
 self.treatment_type_code = "PACKHOUSE"
end


def before_create
  puts "in create IPC"
  validate
  
  self.treatment_type_code = "PACKHOUSE"
  puts "IPC SR: " + self.size_ref
  
  self.item_pack_product_code = self.commodity_code + "_" + self.marketing_variety_code + "_" + self.product_class_code + "_" + self.grade_code + "_" + self.actual_count.to_s + "_" + self.basic_pack_code + "_" + self.cosmetic_code_name + "_" + size_ref                                                
   
 #self.item_pack_product_code = self.commodity_code + "_" + self.marketing_variety_code + "_" + self.product_class_code + "_" + self.grade_code + "_" + self.actual_count.to_s + "_" + self.cosmetic_code_name                                                    
 product = nil
 product = Product.find_by_product_code(self.item_pack_product_code)
 if !product
  product = Product.new
  product.product_code = self.item_pack_product_code
  product.product_type_code = "ITEM_PACK"
  product.product_type = ProductType.find_by_product_type_code("ITEM_PACK")
 
 product.create
 
 end
 puts "before create: size ref: " + self.size_ref
 self.product = product
end

def before_destroy
  self.product.destroy

end


#	=====================
#	 Complex validations:
#	=====================
def validate 
puts "in IPC validate"
#	first check whether combo fields have been selected
	 is_valid = true

    ModelHelper::Validations.validate_combos([{:size_ref => self.size_ref}],self,true)
    self.size_ref = "NOS" if !self.size_ref

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:product_class_code => self.product_class_code}],self)
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_product_class
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:grade_code => self.grade_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_grade
	 end
	 
	if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:treatment_code => self.treatment_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_treatment
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code},{:commodity_code => self.commodity_code},{:marketing_variety_code => self.marketing_variety_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_marketing_variety
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:cosmetic_code => self.cosmetic_code_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_cosmetic_code
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code},{:basic_pack_code => self.basic_pack_code},{:standard_size_count_value => self.standard_size_count_value}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_standard_size_count
	 end
	 
	 if !self.size_ref
	   self.size_ref = "NOS"
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end

end

def validate_uniqueness
	 exists = ItemPackProduct.find_by_commodity_code_and_marketing_variety_code_and_actual_count_and_product_class_code_and_grade_code_and_cosmetic_code_name_and_size_ref_and_basic_pack_code(self.commodity_code,self.marketing_variety_code,self.actual_count,self.product_class_code,self.grade_code,self.cosmetic_code_name,self.size_ref,self.basic_pack_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_code' and 'marketing_variety_code' and 'actual_count' and 'product_class_code' and 'grade_code' and 'cosmetic_code' and size_ref and 'basic_pack_code' ")
	end
end

 def get_ipc_code_for_fg
   self.item_pack_product_code = self.commodity_code + "_" + self.marketing_variety_code + "_" + self.product_class_code + "_" + self.grade_code + "_" + self.actual_count.to_s + "_" + self.cosmetic_code_name + "_" + size_ref   
 end

#	===========================
#	 foreign key validations:
#	===========================

def set_treatment

	treatment = Treatment.find_by_treatment_code_and_treatment_type_code(self.treatment_code,"PACKHOUSE")
	 if treatment != nil 
		 self.treatment = treatment
		 return true
	 else
		errors.add_to_base("combination of: 'treatment_code'  is invalid- it must be unique")
		 return false
	end
end


def set_grade

	grade = Grade.find_by_grade_code(self.grade_code)
	 if grade != nil 
		 self.grade = grade
		 return true
	 else
		errors.add_to_base("value of field: 'grade_code' is invalid- it must be unique")
		 return false
	end
end
 
def set_marketing_variety

	marketing_variety = MarketingVariety.find_by_commodity_group_code_and_commodity_code_and_marketing_variety_code(self.commodity_group_code,self.commodity_code,self.marketing_variety_code)
	 if marketing_variety != nil 
		 self.marketing_variety = marketing_variety
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_group_code' and 'commodity_code' and 'marketing_variety_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_product_class

	product_class = ProductClass.find_by_product_class_code(self.product_class_code)
	 if product_class != nil 
		 self.product_class = product_class
		 return true
	 else
		errors.add_to_base("combination of: 'product_class_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_standard_size_count

	standard_size_count = StandardSizeCount.find_by_commodity_code_and_basic_pack_code_and_standard_size_count_value(self.commodity_code,self.basic_pack_code,self.standard_size_count_value)
	self.actual_count = standard_size_count.actual_count
	 if standard_size_count != nil 
		 self.standard_size_count = standard_size_count
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_code' and 'basic_pack' and 'standard_size_count'  is invalid- it must be unique")
		 return false
	end
end
 
def set_cosmetic_code

	cosmetic_code = CosmeticCode.find_by_cosmetic_code(self.cosmetic_code_name)
	 if cosmetic_code != nil 
		 self.cosmetic_code = cosmetic_code
		 return true
	 else
		errors.add_to_base("combination of: 'cosmetic_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: marketing_variety_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_group_codes

	commodity_group_codes = MarketingVariety.find_by_sql('select distinct commodity_group_code from marketing_varieties').map{|g|[g.commodity_group_code]}
end



def self.get_all_commodity_codes

	commodity_codes = MarketingVariety.find_by_sql('select distinct commodity_code from marketing_varieties').map{|g|[g.commodity_code]}
end



def self.commodity_codes_for_commodity_group_code(commodity_group_code)

	commodity_codes = MarketingVariety.find_by_sql("Select distinct commodity_code from marketing_varieties where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}

	commodity_codes.unshift("<empty>")
 end



def self.get_all_marketing_variety_codes

	marketing_variety_codes = MarketingVariety.find_by_sql('select distinct marketing_variety_code from marketing_varieties').map{|g|[g.marketing_variety_code]}
end



def self.marketing_variety_codes_for_commodity_code_and_commodity_group_code(commodity_code, commodity_group_code)

	marketing_variety_codes = MarketingVariety.find_by_sql("Select distinct marketing_variety_code from marketing_varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.marketing_variety_code]}

	marketing_variety_codes.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: product_class_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_product_class_codes

	product_class_codes = ProductClass.find_by_sql('select distinct product_class_code from product_classes').map{|g|[g.product_class_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: standard_size_count_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes

	commodity_codes = StandardSizeCount.find_by_sql('select distinct commodity_code from standard_size_counts').map{|g|[g.commodity_code]}
end



def self.get_all_basic_packs

	basic_packs = StandardSizeCount.find_by_sql('select distinct basic_pack_code from standard_size_counts').map{|g|[g.basic_pack_code]}
end



def self.basic_packs_for_commodity_code(commodity_code)

	basic_packs = StandardSizeCount.find_by_sql("Select distinct basic_pack_code from standard_size_counts where commodity_code = '#{commodity_code}'").map{|g|[g.basic_pack_code]}

	basic_packs.unshift("<empty>")
 end



def self.get_all_actual_counts

	actual_counts = StandardSizeCount.find_by_sql('select distinct actual_count from standard_size_counts').map{|g|[g.actual_count]}
end

#def self.actual_counts_for_basic_pack_and_commodity_code(basic_pack, commodity_code)
#
#	actual_counts = StandardSizeCount.find_by_sql("Select distinct actual_count from standard_size_counts where basic_pack_code = '#{basic_pack}' and commodity_code = '#{commodity_code}'").map{|g|[g.actual_count]}
#
#	actual_counts.unshift("<empty>")
# end


def self.std_counts_for_basic_pack_and_commodity_code(basic_pack, commodity_code)

	actual_counts = StandardSizeCount.find_by_sql("Select distinct standard_size_count_value from standard_size_counts where basic_pack_code = '#{basic_pack}' and commodity_code = '#{commodity_code}'").map{|g|[g.standard_size_count_value]}

	actual_counts.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: cosmetic_code_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_cosmetic_codes

	cosmetic_codes = CosmeticCode.find_by_sql('select distinct cosmetic_code from cosmetic_codes').map{|g|[g.cosmetic_code]}
end






end
