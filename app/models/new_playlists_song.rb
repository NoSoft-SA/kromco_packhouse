class NewPlaylistsSong < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :new_playlist
	belongs_to :song
 
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
		 is_valid = ModelHelper::Validations.validate_combos([{:playlist_name => self.playlist_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_new_playlist
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:song_title => self.song_title},{:artist_name => self.artist_name},{:album_title => self.album_title}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_song
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_new_playlist

	new_playlist = NewPlaylist.find_by_playlist_name(self.playlist_name)
	 if new_playlist != nil 
		 self.new_playlist = new_playlist
		 return true
	 else
		errors.add_to_base("value of field: 'playlist_name' is invalid- it must be unique")
		 return false
	end
end
 
def set_song

	song = Song.find_by_song_title_and_artist_name_and_album_title(self.song_title,self.artist_name,self.album_title)
	 if song != nil 
		 self.song = song
		 return true
	 else
		errors.add_to_base("combination of: 'song_title' and 'artist_name' and 'album_title'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: song_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_song_titles

	song_titles = Song.find_by_sql('select distinct song_title from song_pdt').map{|g|[g.song_title]}
end



def self.get_all_artist_names

	artist_names = Song.find_by_sql('select distinct artist_name from song_pdt').map{|g|[g.artist_name]}
end



def self.artist_names_for_song_title(song_title)

	artist_names = Song.find_by_sql("Select distinct artist_name from song_pdt where song_title = '#{song_title}'").map{|g|[g.artist_name]}

	artist_names.unshift("<empty>")
 end



def self.get_all_album_titles

	album_titles = Song.find_by_sql('select distinct album_title from song_pdt').map{|g|[g.album_title]}
end



def self.album_titles_for_artist_name_and_song_title(artist_name, song_title)

	album_titles = Song.find_by_sql("Select distinct album_title from song_pdt where artist_name = '#{artist_name}' and song_title = '#{song_title}'").map{|g|[g.album_title]}

	album_titles.unshift("<empty>")
 end






end
