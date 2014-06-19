class Variety < ActiveRecord::Base
  
   #	===========================
# 	Association declarations:
#	===========================
 
	belongs_to :commodity
	belongs_to :rmt_variety
	belongs_to :marketing_variety
 

#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code},{:commodity_code => self.commodity_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_commodity
	 end
	 
	if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:rmt_variety_code => self.rmt_variety_code},{:rmt_variety_code => self.rmt_variety_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_rmt_variety
	 end
	
	
	if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:marketing_variety_code => self.marketing_variety_code},{:marketing_variety_code => self.marketing_variety_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_marketing_variety
	 end
	 
	  
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Variety.find_by_commodity_group_code_and_commodity_code_and_rmt_variety_code_and_marketing_variety_code(self.commodity_group_code,self.commodity_code,self.rmt_variety_code,self.marketing_variety_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_group_code' and 'commodity_code' and 'rmt variety_code' and 'marketing variety code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================

 
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

def set_rmt_variety

	rmt_variety = RmtVariety.find_by_commodity_code_and_rmt_variety_code(self.commodity_code,self.rmt_variety_code)
	 if rmt_variety != nil 
		 self.rmt_variety = rmt_variety
		 return true
	 else
		errors.add_to_base("rmt variety not found in database")
		 return false
	end
end


def set_marketing_variety

	marketing_variety = MarketingVariety.find_by_commodity_code_and_marketing_variety_code(self.commodity_code,self.marketing_variety_code)
	 if marketing_variety != nil 
		 self.marketing_variety = marketing_variety
		 return true
	 else
		errors.add_to_base("marketing variety not found in database")
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


  def Variety.outputs_for_input(schedule_id)
  
    rmt_setup = RmtSetup.find_by_production_schedule_id(schedule_id)
    input_variety = rmt_setup.variety_code
    commodity = rmt_setup.commodity_code
    output_varieties = Variety.find_by_sql("select distinct marketing_variety_code from
                       varieties where rmt_variety_code = '#{input_variety}' and commodity_code = '#{commodity}'").map {|v|
                       v.marketing_variety_code}
   
    return output_varieties
  
  
  end

  
   def Variety.all_output_varieties_for_schedule(schedule_id)
    rmt_setup = RmtSetup.find_by_production_schedule_id(schedule_id)

    commodity = rmt_setup.commodity_code
    output_varieties = Variety.find_by_sql("select distinct marketing_variety_code from
                       varieties where commodity_code = '#{commodity}'").map {|v| v.marketing_variety_code}
   
    return output_varieties
  
  end
  
  


end
