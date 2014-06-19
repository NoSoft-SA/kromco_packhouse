class Album < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
        
  belongs_to :artist
  has_many   :songs
 
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
		 is_valid = ModelHelper::Validations.validate_combos([{:artist_name => self.artist_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_artist
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Album.find_by_artist_name_and_album_title(self.artist_name,self.album_title)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'artist_name' and 'album_title' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_artist

	artist = Artist.find_by_artist_name(self.artist_name)
	 if artist != nil 
		 self.artist_name = artist
		 return true
	 else
		errors.add_to_base("combination of: 'artist_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: artist_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_artist_names

	artist_names = Artist.find_by_sql('select distinct artist_name from artists').map{|g|[g.artist_name]}
end



#def self.get_all_artist_surnames
#
#	artist_surnames = Artist.find_by_sql('select distinct artist_surname from artists').map{|g|[g.artist_surname]}
#end



#def self.artist_surnames_for_artist_name(artist_name)
#
#	artist_surnames = Artist.find_by_sql("Select distinct artist_surname from artists where artist_name = '#{artist_name}'").map{|g|[g.artist_surname]}
#
#	artist_surnames.unshift("<empty>")
# end






end
