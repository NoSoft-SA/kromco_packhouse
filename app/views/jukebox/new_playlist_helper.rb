module Jukebox::NewPlaylistHelper
 def build_nested_playlist_forms
    field_configs = Array.new

      field_configs[field_configs.length()] = {:field_type => 'Screen',
						:field_name => "child_form1",
						:settings =>{:target_action => 'new_new_playlist',
						             :id_value => "is_child_form",:width => 500,:height =>98}}

      field_configs[field_configs.length()] = {:field_type => 'Screen',
						:field_name => "child_form2",
						:settings =>{:target_action => 'list_new_playlists',:width => 500}}

#     field_configs[field_configs.length()] = {:field_type => 'Screen',
#						:field_name => "child_form3",
#						:settings =>{:target_action => 'show_playlist_songs',:width => 500}}


    build_form(nil,field_configs,nil,'list_artists',"kkkk")
  end

 def build_song_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
  
	column_configs[0] = {:field_type => 'text',:field_name => 'song_title'}
	column_configs[1] = {:field_type => 'text',:field_name => 'artist_name'}
	column_configs[2] = {:field_type => 'text',:field_name => 'album_title'}
	column_configs[3] = {:field_type => 'text',:field_name => 'duration'}
  column_configs[4] = {:field_type => 'text',:field_name => 'id'}
  
 
#	----------------------
#	define action columns
@multi_select = "selected_songs"


 return get_data_grid(data_set,column_configs)

end

 def build_song_song_grid(data_set)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'artist_name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'duration'}
	column_configs[2] = {:field_type => 'text',:field_name => 'album_title'}
	column_configs[3] = {:field_type => 'text',:field_name => 'song_title'}
#  column_configs[4] = {:field_type => 'text',:field_name => 'id'}
  column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'play song',
			:settings =>
				 {:link_text => 'play_song',
				:target_action => 'play_songs',
				:id_column => 'id'}}

 return get_data_grid(data_set,column_configs)

end




 
 def build_new_playlist_form(new_playlist,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:new_playlist_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'playlist_name'}




	build_form(new_playlist,field_configs,action,'new_playlist',caption,is_edit)

end
 
 
 def build_new_playlist_search_form(new_playlist,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:new_playlist_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	playlist_names = NewPlaylist.find_by_sql('select distinct playlist_name from new_playlists').map{|g|[g.playlist_name]}
	playlist_names.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'playlist_name',
						:settings => {:list => playlist_names}}

	build_form(new_playlist,field_configs,action,'new_playlist',caption,false)

end



 def build_new_playlist_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'playlist_name'}
#	----------------------
#	define action columns
#	----------------------
column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'manage_playlist',
			:settings =>
				 {:link_text => 'add or remove song_pdt',
				:target_action => 'list_songs',
				:id_column => 'id'}}


	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit new_playlist',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_new_playlist',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete new_playlist',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_new_playlist',
				:id_column => 'id'}}

     end
    column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'current_playlist',
			:settings =>
				 {:link_text => 'current song_pdt',
				:target_action => 'show_playlist_songs',
        
         :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'player',
			:settings =>
				 {:link_text => 'play',
				:target_action => 'player',
        :id_column => 'id'}}

   column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_new_playlist',
        :id_column => 'id'}}


 return get_data_grid(data_set,column_configs)
end

def build_playlist_form(new_playlist,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:new_playlist_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	
	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'playlist',:settings => {:hide_label => false}}


     field_configs[field_configs.length()] = {:field_type => 'Screen',
						:field_name => "child_form3",
						:settings =>{:target_action => 'list_songs',:width => 800}}


   


	build_form(new_playlist,field_configs,action,'new_playlist',caption,is_edit)
	

  end
  def build_upload_form(upload_file,action,caption,is_edit = nil,is_create_retry = nil)
    session[:upload_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new

	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'file',:label_caption => 'Select file'}

    field_configs[1] = {:field_type => 'TextField',
						:field_name => 'upload',:settings => {:hide_label => false}}

    field_configs[2] = {:field_type => 'FileField',
						:field_name => 'upload_file',:settings => 'datafile'}

    build_form(upload_file,field_configs,action,'upload_file',caption,is_edit)

  end
  def build_export_form(song,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:export_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 
    field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'playlist_name'}




	build_form(song,field_configs,action,'export',caption,is_edit,id)

end

end




