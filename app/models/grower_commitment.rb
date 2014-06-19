class GrowerCommitment < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
#	belongs_to :season
	belongs_to :farm
	has_many :commitment
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		# is_valid = ModelHelper::Validations.validate_combos([{:id => self.id},{:farm_code => self.farm_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_farm
	 end
	 if is_valid
		 #is_valid = ModelHelper::Validations.validate_combos([{:season_code => self.season_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_season
#	 end
end

#	===========================
#	 foreign key validations:
#	===========================
#def set_season
#
#	season = Season.find_by_season_code(self.season_code)
#	 if season != nil
#		 self.season = season
#		 return true
#	 else
#		errors.add_to_base("combination of: 'season_code'  is invalid- it must be unique")
#		 return false
#	end
#end
 
def set_farm

	farm = Farm.find_by_farm_code(self.farm_code)
	 if farm != nil 
		 self.farm = farm
		 return true
	 else
		errors.add_to_base("combination of: 'id' and 'farm_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: season_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_seasons
	seasons = Season.find_by_sql('select distinct season from seasons').map{|g|[g.season]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: farm_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_ids

	ids = Farm.find_by_sql('select distinct id from farms').map{|g|[g.id]}
end

def self.get_all_distinct_farms_from_grower_commitment
	farm_codes = Farm.find_by_sql('select distinct farm_code from grower_commitments').map{|g|[g.farm_code]}
end

def self.get_all_farm_codes

	farm_codes = Farm.find_by_sql('select distinct farm_code from farms').map{|g|[g.farm_code]}
end



def self.farm_codes_for_id(id)
	farm_codes = Farm.find_by_sql("Select distinct farm_code from farms where id = '#{id}'").map{|g|[g.farm_code]}
	farm_codes.unshift("<empty>")
 end






end
