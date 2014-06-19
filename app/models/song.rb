class Song < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :artist
	belongs_to :album
  has_and_belongs_to_many   :new_playlists
#  has_many   :new_playlists ,:through => players
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
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:artist_name => self.artist_name},{:album_title => self.album_title}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_album
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Song.find_by_song_title_and_artist_name_and_album_title(self.song_title,self.artist_name,self.album_title)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'song_title' and 'artist_name' and 'album_title' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_artist

	artist = Artist.find_by_artist_name(self.artist_name)
	 if artist != nil 
		 self.artist = artist
		 return true
	 else
		errors.add_to_base("combination of: 'artist_name'   is invalid- it must be unique")
		 return false
	end
end
 
def set_album

	album = Album.find_by_artist_name_and_album_title(self.artist_name,self.album_title)
	 if album != nil 
		 self.album = album
		 return true
	 else
		errors.add_to_base("combination of: 'artist_name' and 'album_title'  is invalid- it must be unique")
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



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: album_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_artist_names

	artist_names = Album.find_by_sql('select distinct artist_name from albums').map{|g|[g.artist_name]}
end



def self.get_all_album_titles

	album_titles = Album.find_by_sql('select distinct album_title from albums').map{|g|[g.album_title]}
end



def self.album_titles_for_artist_name(artist_name)

	album_titles = Album.find_by_sql("Select distinct album_title from albums where artist_name = '#{artist_name}'").map{|g|[g.album_title]}

	album_titles.unshift("<empty>")
 end


def update_file(ffile)

self.update_attribute("ffile", ffile)

end




end
