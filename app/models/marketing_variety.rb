class MarketingVariety < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :variety_group
	belongs_to :commodity
	has_many :track_slms_indicators
	has_one :slms_variety, :as => :variety
	has_many :track_slms_varieties
  #MM072014
  has_many :carton_presort_conversions#, :dependent => :destroy
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :commodity_group_code
	validates_presence_of :marketing_variety_code
	validates_presence_of :commodity_code
#	=====================
#	 Complex validations:
#	=====================
def validate  
    
#    a = self.marketing_variety_description.index("�")
#    j = self.marketing_variety_description
#    i = 0
#    b = ""
#    for i in 0..j.length()
#     
#     b += j[i,1] if i != a - 1
#    end
#    
#    puts b
#    self.marketing_variety_description = b
#    
    #self.marketing_variety_desc.to_sription.gsub!("©","�")
    puts "two"
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_variety_group
#	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code},{:commodity_code => self.commodity_code}],self) 
	 end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_commodity
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
	 
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:variety_group_code => self.variety_group_code}],self) 
	     if is_valid
	        set_variety_group
	     end
	 end
	 
	 
	 
end

def validate_uniqueness
	 exists = MarketingVariety.find_by_commodity_group_code_and_commodity_code_and_marketing_variety_code(self.commodity_group_code,self.commodity_code,self.marketing_variety_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_group_code' and 'commodity_code' and 'marketing_variety_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_variety_group

	variety_group = VarietyGroup.find_by_variety_group_code(self.variety_group_code)
	 if variety_group != nil 
		 self.variety_group = variety_group
		 return true
	 else
		errors.add_to_base("value of field: 'commodity_code' is invalid- it must be unique")
		 return false
	end
end
 
def set_commodity

	commodity = Commodity.find_by_commodity_group_code_and_commodity_code(self.commodity_group_code,self.commodity_code)
	 if commodity != nil 
		 self.commodity = commodity
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_group_code' and 'commodity_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: commodity_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_group_codes

	commodity_group_codes = Commodity.find_by_sql('select distinct commodity_group_code from commodities').map{|g|[g.commodity_group_code]}
end



def self.get_all_commodity_codes

	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
end



def self.commodity_codes_for_commodity_group_code(commodity_group_code)

	commodity_codes = Commodity.find_by_sql("Select distinct commodity_code from commodities where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}

	commodity_codes.unshift("<empty>")
 end






end
