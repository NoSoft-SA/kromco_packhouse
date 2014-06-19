class SongPdt < PDTTransaction

  attr_accessor     :album_title , :artist_name , :duration , :song_title

 
  def build_default_screen


    artist_names = Artist.find(:all).map{|g|g.stage_name}.join(",")
    artist_names = ", ," + artist_names


    field_configs = Array.new

    field_configs[field_configs.length] = {:type=>"drop_down",:name=>"artist_name",:is_required=>"true", :list => artist_names, :value => 'artist_name'}

    field_configs[field_configs.length] = {:type=>"text_box",:name=>"title",:is_required=>"true"}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"duration",:is_required=>"true", :required_type=>"number"}


    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"Add  new  song",:current_menu_item=>"2.3.1.1"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"new_song_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)



    return result_screen_def
   end



   def new_song
       build_default_screen
   end



 def new_song_submit

  song_title = self.pdt_screen_def.get_control_value("title").to_s
  duration = self.pdt_screen_def.get_control_value("duration").to_s
  stage_name = self.pdt_screen_def.get_control_value("artist_name").to_s

   song_track = Song.new

   song_track.title =  song_title
   song_track.duration =  duration
   song_track.stage_name = stage_name
   song_track.create


   result = ["Song Added Successfully"]
   result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,result)

   return result_screen

  end

#=============== active state==============
  def list_songs
   next_state = SongList.new(self)
       self.set_active_state(next_state)
     return next_state.build_default_screen
   end






end



