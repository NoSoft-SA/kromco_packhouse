class NewPlaylist < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
has_and_belongs_to_many :songs

 def self.songs_for_playlist(playlist)

  query = "SELECT song_pdt.song FROM new_playlists_songs " +
          " INNER JOIN song_pdt ON (new_playlists_songs.song_id = song.id) " +
          " INNER JOIN new_playlists ON (new_playlists_songs.new_playlist_id = new_playlist.id)" +
          " WHERE (new_playlists.new_playlist_name = '#{playlist}')"

  results = self.find_by_sql(query).map{|g|[g.song]}

 end

end
