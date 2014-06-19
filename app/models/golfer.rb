class Golfer < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 attr_accessor :country,:club_name


  def country
    self.golf_club.country if self.golf_club
  end

   def club_name
    self.golf_club.club_name if self.golf_club
  end

 

	belongs_to :golf_club
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :country
	validates_presence_of :handicap
	validates_presence_of :club_name
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:country => self.country},{:club_name => self.club_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_golf_club
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Golfer.find_by_golf_club_id_and_name(self.golf_club_id,self.name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'country' and 'club_name' and 'name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_golf_club

	golf_club = GolfClub.find_by_country_and_club_name(self.country,self.club_name)
	 if golf_club != nil 
		 self.golf_club = golf_club
		 return true
	 else
		errors.add_to_base("combination of: 'country' and 'club_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: golf_club_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_countries

	countries = GolfClub.find_by_sql('select distinct country from golf_clubs').map{|g|[g.country]}
end



def self.get_all_club_names

	club_names = GolfClub.find_by_sql('select distinct club_name from golf_clubs').map{|g|[g.club_name]}
end



def self.club_names_for_country(country)

	club_names = GolfClub.find_by_sql("Select distinct club_name from golf_clubs where country = '#{country}'").map{|g|[g.club_name]}

	club_names.unshift("<empty>")
 end






end
