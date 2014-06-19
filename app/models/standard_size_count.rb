class StandardSizeCount < ActiveRecord::Base

 
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :standard_count
	belongs_to :commodity
	belongs_to :basic_pack
	belongs_to :old_pack
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :actual_count
	validates_presence_of :standard_size_count_value
	validates_presence_of :commodity_code
	validates_presence_of :old_pack_code
	validates_presence_of :basic_pack_code
	validates_numericality_of :actual_count
	validates_numericality_of :diameter_mm
	validates_numericality_of :standard_size_count_value
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:standard_size_count_value => self.standard_size_count_value}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_standard_count
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:old_pack_code => self.old_pack_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_old_pack
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_commodity
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:basic_pack_code => self.basic_pack_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_basic_pack
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = StandardSizeCount.find_by_commodity_code_and_standard_size_count_value_and_basic_pack_code_and_actual_count(self.commodity_code,self.standard_size_count_value,self.basic_pack_code,self.actual_count)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_code' and 'standard_size_count_value' and 'basic_pack_code' and 'actual_count' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_standard_count

	standard_count = StandardCount.find_by_standard_count_value_and_commodity_code(self.standard_size_count_value,self.commodity_code)
	 if standard_count != nil 
		 self.standard_count = standard_count
		 return true
	 else
		errors.add_to_base("combination of: 'standard_count_value' and commodity_code  is invalid- it must be unique")
		 return false
	end
end
 
def set_commodity

	commodity = Commodity.find_by_commodity_code(self.commodity_code)
	 if commodity != nil 
		 self.commodity = commodity
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_basic_pack

	basic_pack = BasicPack.find_by_basic_pack_code(self.basic_pack_code)
	 if basic_pack != nil 
		 self.basic_pack = basic_pack
		 return true
	 else
		errors.add_to_base("combination of: 'basic_pack_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_old_pack

	old_pack = OldPack.find_by_old_pack_code(self.old_pack_code)
	 if old_pack != nil 
		 self.old_pack = old_pack
		 return true
	 else
		errors.add_to_base("combination of: 'old_pack_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: standard_count_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_standard_count_values

	standard_count_values = StandardCount.find_by_sql('select distinct standard_count_value from standard_counts').map{|g|[g.standard_count_value]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: commodity_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes

	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: basic_pack_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_basic_pack_codes

	basic_pack_codes = BasicPack.find_by_sql('select distinct basic_pack_code from basic_packs').map{|g|[g.basic_pack_code]}
end


#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: old_pack_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_old_pack_codes

	old_pack_codes = OldPack.find_by_sql('select distinct old_pack_code from old_packs').map{|g|[g.old_pack_code]}
end



 def StandardSizeCount.counts_by_commodity(commodity_code)
 
   counts = StandardSizeCount.find_by_sql("Select distinct standard_size_count_value from standard_size_counts where (
	                      commodity_code = '#{commodity_code}')").map {|c|[c.standard_size_count_value]}
 
 
 end
 
 
end
