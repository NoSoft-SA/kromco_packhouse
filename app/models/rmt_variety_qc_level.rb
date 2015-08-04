class RmtVarietyQcLevel < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :season
	belongs_to :rmt_variety
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :max_pressure
	validates_presence_of :min_sugar
	validates_presence_of :min_pressure
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code},{:rmt_variety_code => self.rmt_variety_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_rmt_variety
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:season_code => self.season_code},{:id => self.id}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_season
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = RmtVarietyQcLevel.find_by_id_and_season_id_and_rmt_variety_id(self.id,self.season_id,self.rmt_variety_id)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'id' and 'season_id' and 'rmt_variety_id' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_season

	season = Season.find_by_season_code_and_id(self.season_code,self.id)
	 if season != nil 
		 self.season = season
		 return true
	 else
		errors.add_to_base("combination of: 'season_code' and 'id'  is invalid- it must be unique")
		 return false
	end
end
 
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
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: season_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_season_codes

	season_codes = Season.find_by_sql('select distinct season_code from seasons').map{|g|[g.season_code]}
end



def self.get_all_ids

	ids = Season.find_by_sql('select distinct id from seasons').map{|g|[g.id]}
end



def self.ids_for_season_code(season_code)

	ids = Season.find_by_sql("Select distinct id from seasons where season_code = '#{season_code}'").map{|g|[g.id]}

	ids.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: rmt_variety_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes

	commodity_codes = RmtVariety.find_by_sql('select distinct commodity_code from rmt_varieties').map{|g|[g.commodity_code]}
end



def self.get_all_rmt_variety_codes

	rmt_variety_codes = RmtVariety.find_by_sql('select distinct rmt_variety_code from rmt_varieties').map{|g|[g.rmt_variety_code]}
end



def self.rmt_variety_codes_for_commodity_code(commodity_code)

	rmt_variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}'").map{|g|[g.rmt_variety_code]}

	rmt_variety_codes.unshift("<empty>")
 end






end
