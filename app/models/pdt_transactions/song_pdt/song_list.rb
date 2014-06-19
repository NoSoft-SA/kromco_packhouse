class SongList < PDTTransactionState

  def initialize(parent)
   self.parent = parent
   populate_songs
    @current_song_index = 0
  end

#================================== List songs screen ===========================   (3)
   def build_default_screen

     @current_song = @songs[@current_song_index]
    field_configs = Array.new

    field_configs[field_configs.length] = {:type=>"text_box",:name=>"song_title",:value=>@current_song[:title]}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"duration",:value=>@current_song[:duration]}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"artist_name",:value=>@current_song[:stage_name]}

    content_header_caption = "List Songs"

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>content_header_caption, :current_menu_item=>"2.3.1.3"}
    buttons = {"B3Label"=>"next", "B3Submit"=>"next_song", "B2Label"=>"", "B2Submit"=>"", "B1Submit"=>"previous_song","B1Label"=>"previous","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }

     if @songs.length > 1
       buttons['B3Enable'] = true if !on_last?
       buttons['B1Enable'] = true if !on_first?
     end

     plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
   end

  

  def on_last?
   @current_song_index == @songs.length() -1
  end


  def on_first?
   @current_song_index == 0
  end

  def new_song
    self.parent.set_active_state(nil)
    self.parent.build_default_screen
  end

 #================== populate songs =====================
  
  def populate_songs()
    @songs = Array.new
    @songs = Song.find(:all).map{|s|{:title => s.title,:duration => s.duration,:stage_name => s.stage_name}}
   
 end

#===================== previous song ======================

  def previous_song()
   @current_song_index -= 1
   build_default_screen
end



#==================== next song =======================
  def next_song
    @current_song_index += 1
    build_default_screen
  end







end