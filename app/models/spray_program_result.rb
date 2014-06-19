class SprayProgramResult < ActiveRecord::Base 

#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :rmt_variety
	belongs_to :grower_commitment
	has_many :mrl_results, :dependent=> :destroy
 
#	============================
#	 Validations declarations:
#	============================
	#validates_numericality_of :spray_program_code

#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid

		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code},{:rmt_variety_code => self.rmt_variety_code},{:spray_result => self.spray_result},{:spray_program_code => self.spray_program_code}],self) 
	end
	
	
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_rmt_variety
	 end
	 if is_valid
	#	 is_valid = ModelHelper::Validations.validate_combos([{:farm_id => self.farm_id}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_spray_program_result
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_rmt_variety

	rmt_variety = RmtVariety.find_by_commodity_code_and_rmt_variety_code(self.commodity_code,self.rmt_variety_code)
	 if rmt_variety != nil 
		 self.rmt_variety = rmt_variety
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_code' and 'rmt_variety_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_spray_program_result

#	spray_program_result = SprayProgramResult.find_by_grower_commitment_id_and_commodity_code_and_rmt_variety_code(self.grower_commitment_id,self.commodity_code,self.rmt_variety_code)
   spray_program_result = SprayProgramResult.find_by_sql("select * from spray_program_results where grower_commitment_id=#{self.grower_commitment_id} and commodity_code='#{self.commodity_code}' and rmt_variety_code='#{self.rmt_variety_code}' and (cancelled=false or cancelled is null)")[0]
	 if spray_program_result == nil 
		 
		 return true
	 else
		errors.add_to_base("This record already exist")
		 return false
	end
end 
 
 
def set_grower_commitment

	grower_commitment = GrowerCommitment.find_by_farm_id(self.farm_id)
	 if grower_commitment != nil 
		 self.grower_commitment = grower_commitment
		 return true
	 else
		errors.add_to_base("value of field: 'farm_id' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: rmt_variety_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes_for_season(season)
	commodity_codes = RmtVariety.find_by_sql("select distinct rmt_varieties.commodity_code from rmt_varieties join seasons on rmt_varieties.commodity_id=seasons.commodity_id where seasons.season='#{season}'").map{|g|[g.commodity_code]}#where season_code='#{season_code}'
end



def self.get_all_rmt_variety_codes

	rmt_variety_codes = RmtVariety.find_by_sql('select distinct rmt_variety_code from rmt_varieties').map{|g|[g.rmt_variety_code]}
end



def self.rmt_variety_codes_for_commodity_code(commodity_code)

	rmt_variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}'").map{|g|[g.rmt_variety_code]}

	rmt_variety_codes.unshift("<empty>")
 end






end
