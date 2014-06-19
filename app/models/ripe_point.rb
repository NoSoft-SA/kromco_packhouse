class RipePoint < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
  attr_accessor :new_ripe_point_code ,:new_rmt_product_code,:treatment_code2
 
	belongs_to :cold_store_type
	belongs_to :pc_code
	belongs_to :treatment
	belongs_to :ripe_time
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :cold_store_type_code
	validates_presence_of :ripe_point_code
	validates_presence_of :pc_code_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:treatment_type_code => self.treatment_type_code},{:treatment_code => self.treatment_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_treatment
	 end
	 
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:ripe_code => self.ripe_code}],self) 
	end
	
	 if is_valid
		 is_valid = set_ripe_time
	 end
	

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:pc_code_code => self.pc_code_code}],self) 
	 end
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pc_code
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:cold_store_type_code => self.cold_store_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_cold_store_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = RipePoint.find_by_treatment_code_and_cold_store_type_code_and_pc_code_code_and_ripe_point_code(self.treatment_code,self.cold_store_type_code,self.pc_code_code,self.ripe_point_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'treatment_code' and 'cold_store_type_code' and 'pc_code_code' and 'ripe_point_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_cold_store_type

	cold_store_type = ColdStoreType.find_by_cold_store_type_code(self.cold_store_type_code)
	 if cold_store_type != nil 
		 self.cold_store_type = cold_store_type
		 return true
	 else
		errors.add_to_base("combination of: 'cold_store_type_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_pc_code

	pc_code = PcCode.find_by_pc_code(self.pc_code_code)
	 if pc_code != nil 
		 self.pc_code = pc_code
		 return true
	 else
		errors.add_to_base("combination of: 'pc_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_treatment

	treatment = Treatment.find_by_treatment_type_code_and_treatment_code(self.treatment_type_code,self.treatment_code)
	 if treatment != nil 
		 self.treatment = treatment
		 return true
	 else
		errors.add_to_base("combination of: 'treatment_type_code' and 'treatment_code'  is invalid- it must be unique")
		 return false
	end
end

def set_ripe_time

	ripe_time = RipeTime.find_by_ripe_code(self.ripe_code)
	 if ripe_time != nil 
		 self.ripe_time = ripe_time
		 return true
	 else
		errors.add_to_base("ripe time  is invalid- not found in database!")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: cold_store_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_cold_store_type_codes

	cold_store_type_codes = ColdStoreType.find_by_sql('select distinct cold_store_type_code from cold_store_types').map{|g|[g.cold_store_type_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: pc_code_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_pc_codes

	pc_codes = PcCode.find_by_sql('select distinct pc_code from pc_codes').map{|g|[g.pc_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: treatment_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_treatment_type_codes

	treatment_type_codes = Treatment.find_by_sql('select distinct treatment_type_code from treatments').map{|g|[g.treatment_type_code]}
end



def self.get_all_treatment_codes

	treatment_codes = Treatment.find_by_sql('select distinct treatment_code from treatments').map{|g|[g.treatment_code]}
end



def self.treatment_codes_for_treatment_type_code(treatment_type_code)

	treatment_codes = Treatment.find_by_sql("Select distinct treatment_code from treatments where treatment_type_code = '#{treatment_type_code}'").map{|g|[g.treatment_code]}

	treatment_codes.unshift("<empty>")
 end






end
