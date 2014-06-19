class PackGroupsCountsConfig < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :standard_count
	belongs_to :size
 
#	============================
#	 Validations declarations:
#	============================
	
	validates_numericality_of :position

 def cancel_clear_combo_prompts
    true
  end

#	=====================
#	 Complex validations:
#	=====================

def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 
	 if is_valid
		 ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code}],self)
	 end
	 
	 has_size = true
	 if is_valid
		has_size = ModelHelper::Validations.validate_combos([{:size_code => self.size_code}],self,true)
	 end
	 puts "is_valid: " + is_valid.to_s + " has size: " + has_size.to_s
	 if is_valid && has_size
		 is_valid = set_size
	 end
	 
	has_count = true
	if is_valid 
	 has_count = self.standard_size_count_value > 0  
	end
	#now check whether fk combos combine to form valid foreign keys
	
	 if is_valid && has_count == true
		 is_valid = set_standard_count
	 end
	 
	 
	 if !self.size_code && self.standard_size_count_value == 0
	   is_valid = false
	   errors.add_to_base("You must select either a size value or a standard_size_count_value")
	 end
	 
	 if is_valid && self.size_code && self.standard_size_count_value > 0
	   is_valid = false
	   errors.add_to_base("You cannot select both a size value and a standard_size_count_value <br>
	                      Choose one and the other to 'empty'")
	 end
	   
	 
	 #validates uniqueness for this record
	 if self.new_record? && is_valid == true
		 validate_uniqueness
	 end
	 
	 self.standard_size_count_value = nil if  self.standard_size_count_value == 0
end

def validate_uniqueness
	 exists = PackGroupsCountsConfig.find_by_commodity_code_and_standard_size_count_value_and_size_code(self.commodity_code,self.standard_size_count_value,self.size_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_code' and 'standard_size_count_value' and 'size_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_standard_count

	standard_count = StandardCount.find_by_commodity_code_and_standard_count_value(self.commodity_code,self.standard_size_count_value)
	 if standard_count != nil 
		 self.standard_count = standard_count
		 return true
	 else
		errors.add_to_base("'standard_size_count_value'  is invalid- not found in database")
		 return false
	end
end
 
def set_size
    puts "set size"
	size = Size.find_by_size_code_and_commodity_code(self.size_code,self.commodity_code)
	 if size != nil 
		 self.size = size
		 return true
	 else
		errors.add_to_base("'size_code'  is invalid- not found in database")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: standard_count_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes

	commodity_codes = StandardCount.find_by_sql('select distinct commodity_code from standard_counts').map{|g|[g.commodity_code]}
end



def self.get_all_standard_size_count_values

	standard_size_count_values = StandardCount.find_by_sql('select distinct standard_count_value from standard_counts').map{|g|[g.standard_count_value]}
end



def self.standard_size_count_values_for_commodity_code(commodity_code)

	standard_size_count_values = StandardCount.find_by_sql("Select distinct standard_count_value from standard_counts where commodity_code = '#{commodity_code}'").map{|g|[g.standard_count_value]}

	standard_size_count_values.unshift("<empty>")
 end




end
