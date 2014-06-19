require File.dirname(__FILE__) + '/../../../lib/diagnostics.rb'
#require File.dirname(__FILE__) + "/../../../app/helpers/production/carton_setup_helper.rb"

class Diagnostics::MidwareController < ApplicationController

   layout "content"
	 
def program_name?
	"midware"  		
end

def admin_exceptions?
	#["add_user"]
end
  
def list_palletizing_errors
    return if authorise_for_web('midware','read') == false 

 	if params[:page]!= nil 

 		session[:midware_error_log_page] = params['page']
		 render_list_palletizing_errors

		 return 
	else
		session[:midware_error_log_page] = nil
	end
	
	  t1 = Date.today
    t2 = Date.today + 1
    @t1 = t1.strftime("%Y-%m-%d")
    @t2 = t2.strftime("%Y-%m-%d")

    list_query = "@midware_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
	  @midware = MidwareErrorLog.find(:all, 
	         :conditions =>['mw_type = ? and error_date_time between ? and  ?', 'PALLETISING', '#{@t1}', '#{@t2}'],
			 :limit => @midware_pages.items_per_page,
			 :offset => @midware_pages.current.offset)"
	session[:query] = list_query
	render_list_palletizing_errors
end

def render_list_palletizing_errors
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:midware_error_log_page] if session[:midware_error_log_page]
	
	@current_page = params['page'] if params['page']
	
	@midware =  eval(session[:query]) if !@midware
	
	if @midware.length() < 0 || @midware.length() > 0
    render :inline => %{
      <% grid            = build_midware_grid(@midware,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of palletizing errors' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
	else
	   render :inline => %{
		<% @content_header_caption = "'No palletizing errors found'"%>
		
	},:layout => 'content'
	end
end

def view_paging_handler

  if params[:page]
	session[:midware_error_log_page] = params['page']
  end
  render_list_palletizing_errors
end

def view_details
    id = params[:id]
	 if id && @mid = MidwareErrorLog.find(id)
		render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<%= view_midware_error_log(@mid,"view_paging_handler")%>

		}, :layout => 'content'

	 end
end

def view_carton
    begin
      my_res = get_carton_number
      if my_res!= ""
          num  = my_res.strip
          @carton = Carton.find(:first, :conditions =>["carton_number = ?", num])
          if @carton!=nil
              render :inline => %{
                  <% @content_header_caption = "'view carton'"%>
                  <%= view_carton_record(@carton,"view_paging_handler")%>
              }, :layout => 'content'
          else
              raise "Carton Number unknown"
          end
      else
          raise "carton number is unknown"
      end
    rescue
        raise_error "CARTON NUMBER:"
    end
end

def view_pallet
    #begin
        my_res = get_carton_number
        if my_res!=nil
            num = my_res.strip
            if num!=nil
                @carton = Carton.find(:first, :conditions =>["carton_number = ?", num])
                if @carton!=nil
                    @pallet = Pallet.find(:first, :conditions =>["id = ?", @carton.pallet_id])
                    if @pallet!=nil
                        render :inline => %{
                            <% @content_header_caption = "'view pallet'"%>
                            <%= view_pallet_record(@pallet,"view_paging_handler")%>
                        }, :layout => 'content'
                    else
                        raise "Pallet Not Found"
                    end
                else
                    raise "Carton record not unknown"
                end
            else
                raise "Carton Number unknown"
            end
        else
            raise "Carton Number unknown"
        end
    #rescue
        #raise "Pallet could not be displayed"
    #end
end

def view_pallet2
    id = params[:id]
    @pallet = Pallet.find(:first, :conditions =>["pallet_number = ?", id])
    if @pallet!=nil
        render :inline => %{
            <% @content_header_caption = "'view pallet'"%>
            <%= view_pallet_record(@pallet,"view_paging_handler")%>
        }, :layout => 'content'
    else
        raise "Pallet Not Found"
    end
end

def view_pallet_from_carton_form_palletizing
    id = params[:id]
    if id && @pallet = Pallet.find(id)
		render :inline => %{
		<% @content_header_caption = "'view pallet'"%> 

		<%= view_pallet_record(@pallet,'view_paging_handler')%>

		}, :layout => 'content'

	 end
end

def view_cartons
    id = params[:id]
    if id!= nil 
	    list_query = "@cartons = Carton.find(:all, :conditions =>['pallet_id = ?', '#{id}'])"
    		 
        session[:cart] = list_query
	    render_list_pallet_cartons
    end
end

def render_list_pallet_cartons
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
    @cartons =  eval(session[:cart]) if !@cartons
    @carton_pages = nil
    render :inline => %{
      <% grid            = build_pallet_cartons_grid(@cartons,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of cartons' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def get_carton_number
  id = params[:id]
  if id && @mid = MidwareErrorLog.find(id)
      if @mid.short_description.include? "none"
          cn = @mid.short_description.index(":")
          cn_res = @mid.short_description[cn+46,15]
          @cnArray = cn_res.split(/\s*/)
          c_num = ""
          @cnArray.each do |c|
              if (c == ":") 
                  c_num.concat("")
              elsif(c=="<")
                  c_num.concat("")
              elsif(c==",")
                  c_num.concat("")
              elsif(c=="d")
                  c_num.concat("")
              elsif(c=="?")
                  c_num.concat("")
              elsif(c=="A")
                  c_num.concat("")
              elsif(c=="a")
                  c_num.concat("")
              elsif(c=="B")
                  c_num.concat("")
              elsif(c=="^")
                  c_num.concat("")
              elsif(c=="s")
                  c_num.concat("")
              else
                  c_num.concat(c)
              end
          end
      end
   end
   return c_num
end

def get_skip_ip
    id = params[:id]
    retval = nil
    if id && @mid = MidwareErrorLog.find(id)
        if @mid.short_description != nil
            i= @mid.short_description.index(":")
            result = @mid.short_description[i+1,14]
            @strArray = result.split(/\s*/)
            ip = ""
            @strArray.each do |chr|
              if (chr!= ",")
              if(chr != " ")
              # only these characters will be added to the ip string
              allowed_char = ["0","1","2","3","4","5","6","7","8","9","."]
              # tests that the char is founded in the 'allowed_char ' array 
              if (allowed_char.index(chr) != nil)
                ip.concat(chr)
           
           
                end
                end
              end
            end
            retval = ip
         end
    end
    return retval
end

def raise_error(msg)		
    raise msg + "Carton could not be displayed[carton number unknown]" 		
end
  def read_log_file()

  file_name =  view_log().to_s
  error_logger = ApplicationHelper::Log_viewer_html_converter.new()
  render :inline => error_logger.read_log_file(file_name,params[:id],get_carton_number)

  end
  def get_bay_nr
      id  = params[:id]
      @mid =  MidwareErrorLog.find(id)
      short_description_array = @mid.short_description.split("(")

      bay_nr_half = short_description_array[1].split(",")
      bay_nr_array = bay_nr_half[1].split(":")
      bay_nr = bay_nr_array[1].to_i



  end
  def view_log

   id  = params[:id]
   # The record is retrieved from the database
   @mid   = MidwareErrorLog.find(id.to_f)
   #puts @mid.mw_type.to_s
   #tests of what kind the mw_type is because for palletinzing a bay number is also required
    if(@mid.mw_type.to_s == "PALLETISING")
   
    bay_nr =  get_bay_nr
    end
  #  if(@mid.mw_type.to_s == "CARTON_LABELING")
   # cartin_labeling_ip = get_skip_ip
   
   # end
   # this takes the errordate from the database and reformat it so that it correspond to the text file
     errordate =@mid.error_date_time.strftime("%d-%m-%Y")
     errordate  =errordate.split("-")
     errordate[0] = errordate[0].to_i
     errordate[1] = errordate[1].to_i
     errordate = errordate.join '-'

   begin
     my_ip = get_skip_ip
   # puts my_ip+"_*"
   # puts @mid.mw_type.to_s
   # 
     if (my_ip == nil)
        raise " ip coud not be created"
     else
         required_file = ""
         time = Time.now
         #checks for each mw_type because every mw_type has a different location where it is located
          if(@mid.mw_type.to_s == "PALLETISING")
    
             folder = Dir.new(Diagnostics.download_path + my_ip)
          end
          
          if(@mid.mw_type.to_s ==  "CARTON_LABELING")
    
             folder = Dir.new( Diagnostics.download_path_carton_labelling_log_path + my_ip)
          end
          
          if(@mid.mw_type.to_s == "BIN_TIPPING")
    
                folder = Dir.new(  Diagnostics.download_path_bintipping_path + my_ip )
                
          end
  
  # runs through the files in the folder testing with the file names
  #
          folder.each do |f|
                
             # puts  date_section_alone_array.to_s
              #palletizing has a file name that has a bay number before the date
                if(@mid.mw_type.to_s == "PALLETISING")
          
                file_name_array = f.split("#")
                bay_nr_from_file_array = file_name_array[0].split("_")
                bay_nr_from_file = bay_nr_from_file_array[1].to_i
                date_section = file_name_array[1].to_s.split(".")
                date_section_alone_array = date_section[0].to_s.gsub("_","-")
                else
                  # 'Day_12_1_2008.txt' the file is splitted up from the file extension '.txt' and the 'Day_' is removed      
                  date_from_file_array =f.split(".")
                  date_section_alone_array = date_from_file_array[0].to_s.gsub("_","-")   
                  date_section_alone_array = date_section_alone_array.to_s.slice(4,date_section_alone_array.to_s.length)
             end
   
            # tests if the date from the database is the same as the extracted date from the file name
            if errordate == date_section_alone_array.to_s
            
            #tests that the bay nr from the db and the file is the same
            #adds the file name to the folder and ip string
                if(@mid.mw_type.to_s == "PALLETISING" and   bay_nr_from_file ==  bay_nr )
               
                  required_file = Diagnostics.download_path + my_ip + "//" + f 
                
                end
                
                if(@mid.mw_type.to_s ==  "CARTON_LABELING")
               
                   required_file = Diagnostics.download_path_carton_labelling_log_path + my_ip + "//" + f 
                  
                end
                
                if(@mid.mw_type.to_s == "BIN_TIPPING")
               
                   required_file = Diagnostics.download_path_bintipping_path + my_ip + "//" + f 
                   
                end
            end
   
   end
puts required_file
# tests that the required string isnt empty and that a file name have been added
       if (required_file !=  folder.to_s and required_file != "" )
      
            return required_file       
          #  send_file(required_file)
          # link_to "View Image", @image, :popup => ['new_window_name', 'height=300,width=600']
          else
            raise "Log file not found!"
    end
   
   end
    rescue
     raise "Log file not found!"
   
   end     
end
#     
#          if(@mid.mw_type.to_s == "PALLETISING")
#          
#           file_name_array = f.split("#")
#           bay_nr_from_file_array =file_name_array[0].split("_")
#           bay_nr_from_file = bay_nr_from_file_array[1].to_i
#           date_section = file_name_array[1].to_s.split(".")
#           date_section_alone_array =date_section[0].to_s.gsub("_","-")
#       end
#       
#         bay_nr_from_file_array =f.split("_")
#         bay_nr_from_file = bay_nr_from_file_array[1].to_i
#         date_section = file_name_array[1].to_s.split(".")
#         date_section_alone_array =date_section[0].to_s.gsub("_","-")
#    
#             if errordate == date_section_alone_array.to_s #and   bay_nr_from_file ==  bay_nr 
#             puts "retrieved file "+ required_file
#            # if
#              if(@mid.mw_type.to_s == "PALLETISING" and   bay_nr_from_file ==  bay_nr )
#                required_file = Diagnostics.download_path + my_ip + "//" + f 
#              end
#              if(@mid.mw_type.to_s ==  "CARTON_LABELING")
#
#                 required_file = Diagnostics.download_path_carton_labelling_log_path + my_ip + "//" + f 
#                puts required_file
#               end
#             if(@mid.mw_type.to_s == "BIN_TIPPING")
#             puts "2****2"
#             end
#             end
#          end
#          
#         if required_file != ""
#            return required_file       
#          #  send_file(required_file)
#          # link_to "View Image", @image, :popup => ['new_window_name', 'height=300,width=600']
#    end
#
#
#         
#      end
#   rescue
#      raise "Log file not found!"
#   end

#def view_log
#   begin
#     my_ip = get_skip_ip
#     if (my_ip == nil)
#        raise "Palletizing Log file unknown"
#     else
#         required_file = ""
#         time = Time.now
#          folder = Dir.new(Diagnostics.download_path + my_ip)
#          folder.each do |f|
#             file_time = File.stat(Diagnostics.download_path + my_ip + "//" + f).ctime
#             if time.strftime("%d-%m-%Y") == file_time.strftime("%d-%m-%Y")
#                required_file = Diagnostics.download_path + my_ip + "//" + f 
#             end
#          end
#          if required_file != ""
#              send_file(required_file)
#          else
#              raise "Palletizing Log file not found"
#          end
#      end
#   rescue
#      raise "Palletizing Log file not found!"
#   end
#end

#***************************BIN TIPPING METHODS****************************************************

def list_bintipping_errors
    return if authorise_for_web('midware','read') == false 

 	if params[:page]!= nil 

     	 session[:midware_error_log_page] = params['page']
		 render_list_bintipping_errors

		 return 
	else
		session[:midware_error_log_page] = nil
	end
	
    @type = 'BIN_TIPPING'
    t1 = Date.today
    t2 = Date.today + 1
    @t1 = t1.strftime("%Y-%m-%d")
    @t2 = t2.strftime("%Y-%m-%d")

    list_query = "@midware_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
	     @midware = MidwareErrorLog.find(:all,
	         :conditions =>['mw_type = ? and error_description not like ? and error_date_time > ? and error_date_time < ?', '#{@type}', '%A valid bin was scanned to cancel the invalid bin%','#{@t1}','#{@t2}'],
			 :limit => @midware_pages.items_per_page,
			 :offset => @midware_pages.current.offset)"
	session[:query] = list_query
	
	render_list_bintipping_errors
end

def render_list_bintipping_errors

    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:midware_error_log_page] if session[:midware_error_log_page]
	
	@current_page = params['page'] if params['page']
	
	@midware =  eval(session[:query]) if !@midware
	if @midware.length()< 0 || @midware.length()> 0
    render :inline => %{
      <% grid            = build_bintipping_grid(@midware,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of bin tipping errors' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
        render :inline => %{
  		<% @content_header_caption = "'No bin tipping errors found'"%>
  		
  	},:layout => 'content'
    end
end

def view_paging_handler_bintipping
    if params[:page]
  	   session[:midware_error_log_page] = params['page'] 
  	   #@bin_tipping = eval(session[:query]) 
    end
    render_list_bintipping_errors  
end

def view_bintipping_details
    id = params[:id]
	 if id && @mid = MidwareErrorLog.find(id)
		render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<%= view_bintipping_details_form(@mid,'view_paging_handler_bintipping')%>

		}, :layout => 'content'

	 end
end

def view_bin

    @bin = bin_number
    @bin_record = nil
    if @bin!=nil
        @bin_record = BinsTipped.find_by_bin_id(@bin)
        if @bin_record==nil
           @bin_record = BinsTippedInvalid.find_by_bin_id(@bin)
        end
        render :inline => %{
		<% @content_header_caption = "'view bin'"%> 

		<%= view_bin_form(@bin_record,'view_paging_handler_bintipping')%>

		}, :layout => 'content'
    else
        render :inline => %{
		<% @content_header_caption = "'view bin'"%> 

		    <font color='blue'>Bin not found!</font>

		}, :layout => 'content'
          
    end
end

def bin_number
    id = params[:id]
    
    ids = id.split("$")
    @required_bin_id = ids[1]
    return @required_bin_id
end

def get_bin_id
    id = params[:id]
    retval = nil
    if id && @mid = MidwareErrorLog.find(id)
        if @mid.short_description != nil
            i= @mid.short_description.index("_")
            result = @mid.short_description[i+1,19]
            @strArray = result.split(/\s*/)
            my_bin = ""
            @strArray.each do |chr|
              if (chr!= ",")
                my_bin.concat(chr)
              end
            end
            retval = my_bin
         end
    end
    return retval
end

#******************************END OF BIN TIPPING METHODS******************************************


#**************************************************************************************************
#                              START OF CARTON LABELLING METHODS
#******************************                                ************************************

def list_carton_labeling_errors
    return if authorise_for_web('midware','read') == false 

 	if params[:page]!= nil 

 		session[:midware_error_log_page] = params['page']
		 render_list_carton_labeling_errors

		 return 
	else
		session[:midware_error_log_page] = nil
	end
	
	@type = 'CARTON_LABELING'
	t1 = Date.today
    t2 = Date.today + 1
    @t1 = t1.strftime("%m/%d/%Y")
    @t2 = t2.strftime("%m/%d/%Y")

    list_query = "@midware_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
	  @midware = MidwareErrorLog.find(:all, 
	         :conditions =>['mw_type = ? and error_date_time > ? and error_date_time < ?', '#{@type}', '#{@t1}', '#{@t2}'],
			 :limit => @midware_pages.items_per_page,
			 :offset => @midware_pages.current.offset)"
	session[:query] = list_query
	render_list_carton_labeling_errors
end


def view_paging_handler2

  if params[:page]
	session[:midware_error_log_page] = params['page']
  end
  render_list_carton_labeling_errors
end


def render_list_carton_labeling_errors
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:midware_error_log_page] if session[:midware_error_log_page]
	
	@current_page = params['page'] if params['page']
	
	@midware =  eval(session[:query]) if !@midware
	
	if @midware.length() < 0 || @midware.length() > 0
    render :inline => %{
      <% grid            = build_carton_labeling_grid(@midware,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of carton labeling errors' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
   else
      render :inline => %{
                        <% @content_header_caption = "'No carton labeling errors found'"%>
                		
                }, :layout => 'content'
   end
end


def view_carton_labeling_error_details
    id = params[:id]
	 if id && @mid = MidwareErrorLog.find(id)
		render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<%= view_carton_labeling_error_log(@mid,'view_paging_handler2')%>

		}, :layout => 'content'

	 end
end


def create_station_code
      id = params[:id]
      @ret = nil
      if id && @mid = MidwareErrorLog.find(id)
          if @mid.short_description!=nil
              i = @mid.short_description.index("code")
              result = @mid.short_description[i+1,10]
              @strArray = result.split(/\s*/)
              @stat_code = ""
              @strArray.each do |chr|
                  if(chr == "")
                    @stat_code.concat("")
                  elsif(chr == ":")
                    @stat_code.concat("")
                  elsif(chr == "c")
                    @stat_code.concat("")
                  elsif(chr == "o")
                    @stat_code.concat("")
                  elsif(chr == "d")
                    @stat_code.concat("")
                  elsif(chr == "e")
                    @stat_code.concat("")
                  else
                    @stat_code.concat(chr)
                  end
              end
              @ret = @stat_code.strip
          end
      end
      return @ret
  end
  
  def view_carton_setup_details
    begin
        @retval = create_station_code
        if @retval != nil
            @active_device_rec = ActiveDevice.find(:first, :conditions=>["active_device_code = ?", '#{@retval}'])
            if @active_device_rec != nil
                @active_carton_link_rec = ActiveCartonLink.find(:first, :conditions=>["station_code = ? and production_run_id = ?", '#{@active_device_rec.active_device_code}', '#{@active_device_rec.production_run_id}'])
                if @active_carton_link_rec != nil
                    @carton_setup_rec = CartonSetup.find(:first, :conditions=>["id = ?", '#{@active_carton_link_rec.carton_setup_id}'])
                    if @carton_setup_rec != nil
                        render :inline => %{
                      		<% @content_header_caption = "'view carton setup'"%> 
                      
                      		<%= view_carton_setup_form(@carton_setup_rec,'view_paging_handler2')%>
                      
                      		}, :layout => 'content'
              		else
              		    render :inline => %{
              		          <% @content_header_caption = "'view carton setup'"%>
              		          <font color='black'><b>carton setup record not Found</b></font>
              		    
              		    }, :layout=>'content'
                      	#raise "Carton setup record not Found"	
                    end
                else
                    render :inline => %{
                          <% @content_header_caption = "'view carton setup'"%>
                          <font color='black'><b>active carton link record unknown</b></font>
                        }, :layout=>'content'
                    #raise "Active carton link record unknown"
                end
            else
                  render :inline => %{
                          <% @content_header_caption = "'view carton setup'"%>
                          <font color='black'><b>active device record unknown</b></font>
                  
                  }, :layout =>'content'
                  #raise "Active Device Record unknown"
                  
            end
        else
             #render :inline => %{<font color='black'><b>station code unknown</b></font>}
             #raise "Station code unknown"
        end
    rescue
        raise "Carton setup record could not be displayed"
    end
  end

#***************************************END OF CARTON LABELLING***********************************


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                         BAD SCANS CODE
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def list_bad_scans
    return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:midware_error_log_page] = params['page']
		 render_list_bad_scans_errors

		 return 
	else
		session[:midware_error_log_page] = nil
	end
	
	t1 = Date.today
	t2 = Date.today + 1
	@today = t1.strftime("%m/%d/%Y")
	@tomorrow = t2.strftime("%m/%d/%Y")
	@type = 'PALLETISING'

#    list_query = "@badscans_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
#	  @badscans = MidwareErrorLog.find(:all, 
#	         :conditions =>['mw_type = ? and error_description like ? and error_date_time > ? and error_date_time < ?', 'PALLETISING', '%java.lang.NumberFormatException%', '#{@today}', '#{@tomorrow}'],
#			 :limit => @badscans_pages.items_per_page,
#			 :offset => @badscans_pages.current.offset)"
    list_query = "@badscans_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
	  @badscans = MidwareErrorLog.find(:all, 
	         :conditions =>['mw_type = ? and error_description like ? and error_date_time > ? and error_date_time < ?', '#{@type}', '%java.lang.NumberFormatException%', '#{@today}', '#{@tomorrow}'],
	         :select =>'distinct short_description',
			 :limit => @badscans_pages.items_per_page,
			 :offset => @badscans_pages.current.offset)"
	session[:query] = list_query
	render_list_bad_scans_errors
end

def render_list_bad_scans_errors
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:midware_error_log_page] if session[:midware_error_log_page]
	
	@current_page = params['page'] if params['page']
	
	@badscans =  eval(session[:query]) if !@badscans
	if @badscans.length() < 0 || @badscans.length() > 0
    render :inline => %{
      <% grid            = build_bad_scans_grid(@badscans,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of bad scans' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
   else
      render :inline => %{
                    <% @content_header_caption = "'No bad scans errors found'"%>
            }, :layout => 'content'
   end
end

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                         END OF BAD SCANS CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                         PDT CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def list_pdt_errors
    return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:midware_error_log_page] = params['page']
		 render_list_pdt_errors

		 return 
	else
		session[:midware_error_log_page] = nil
	end
	
	t1 = Date.today
	t2 = Date.today + 1
	@today = t1.strftime("%Y-%m-%d")
	@tomorrow = t2.strftime("%Y-%m-%d")
	@type = 'PdtSymbol6800'

    list_query = "@pdt_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
	  @pdt = MidwareErrorLog.find(:all, 
	         :conditions =>['mw_type = ? and error_date_time > ? and error_date_time < ?', '#{@type}', '#{@today}', '#{@tomorrow}'],
			 :limit => @pdt_pages.items_per_page,
			 :offset => @pdt_pages.current.offset)"
	session[:query] = list_query
	render_list_pdt_errors
end

def render_list_pdt_errors
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:midware_error_log_page] if session[:midware_error_log_page]
	
	@current_page = params['page'] if params['page']
	
	@pdt =  eval(session[:query]) if !@pdt
	if @pdt.length() < 0 || @pdt.length() > 0
    render :inline => %{
      <% grid            = build_pdt_grid(@pdt,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of pdt errors' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
   else
      render :inline => %{
                    <% @content_header_caption = "'No pdt errors found'"%>
            }, :layout => 'content'
   end
end

def view_pdt_details
    id = params[:id]
	 if id && @pdt_error = MidwareErrorLog.find(id)
		render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<%= view_pdt_details_form(@pdt_error,'view_paging_handler_pdt')%>

		}, :layout => 'content'
     else
        render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<font color='blue'><b>record not found!</b></font>

		}, :layout => 'content'
	 end
end

def view_paging_handler_pdt
    if params[:page]
  	   session[:midware_error_log_page] = params['page'] 
    end
    render_list_pdt_errors
end

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                         END OF PDT CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                         REBIN LABELING CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def list_rebin_labeling
    return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:midware_error_log_page] = params['page']
		 render_list_rebin_labeling

		 return 
	else
		session[:midware_error_log_page] = nil
	end
	
	t1 = Date.today
	t2 = Date.today + 1
	@today = t1.strftime("%Y-%m-%d")
	@tomorrow = t2.strftime("%Y-%m-%d")
	@type = 'REBIN_LABELING'

    list_query = "@rebin_labeling_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
	  @rebin_labeling = MidwareErrorLog.find(:all, 
	         :conditions =>['mw_type = ? and error_date_time > ? and error_date_time < ?', '#{@type}', '#{@today}', '#{@tomorrow}'],
			 :limit => @rebin_labeling_pages.items_per_page,
			 :offset => @rebin_labeling_pages.current.offset)"
	session[:query] = list_query
	render_list_rebin_labeling
end

def render_list_rebin_labeling
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:midware_error_log_page] if session[:midware_error_log_page]
	
	@current_page = params['page'] if params['page']
	
	@rebin_labeling =  eval(session[:query]) if !@rebin_labeling
	if @rebin_labeling.length() < 0 || @rebin_labeling.length() > 0
    render :inline => %{
      <% grid            = build_rebin_labeling_grid(@rebin_labeling,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of rebin labeling errors' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
   else
      render :inline => %{
                    <% @content_header_caption = "'No rebin labeling errors found'"%>
            }, :layout => 'content'
   end
end

def view_rebin_labeling_details
    id = params[:id]
	 if id && @rebin_labeling_error = MidwareErrorLog.find(id)
		render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<%= view_rebin_labeling_details_form(@rebin_labeling_error,'view_paging_handler_rebin_labeling')%>

		}, :layout => 'content'
     else
        render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<font color='blue'><b>record not found!</b></font>

		}, :layout => 'content'
	 end
end

def view_paging_handler_rebin_labeling
    if params[:page]
  	   session[:midware_error_log_page] = params['page'] 
    end
    render_list_rebin_labeling
end

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                         END REBIN LABELING CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                         ALL MIDWARE ERRORS CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def list_all_midware_errors
    return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:midware_error_log_page] = params['page']
		 render_list_all_midware_errors

		 return 
	else
		session[:midware_error_log_page] = nil
	end
	
	t1 = Date.today
	t2 = Date.today + 1
	@today = t1.strftime("%Y-%m-%d")
	@tomorrow = t2.strftime("%Y-%m-%d")
	#@type = 'REBIN_LABELING'

    list_query = "@all_midware_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
	  @all_midware = MidwareErrorLog.find(:all, 
	         :conditions =>['error_date_time > ? and error_date_time < ?', '#{@today}', '#{@tomorrow}'],
			 :limit => @all_midware_pages.items_per_page,
			 :offset => @all_midware_pages.current.offset)"
	session[:query] = list_query
	render_list_all_midware_errors
end

def render_list_all_midware_errors
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:midware_error_log_page] if session[:midware_error_log_page]
	
	@current_page = params['page'] if params['page']
	
	@all_midware =  eval(session[:query]) if !@all_midware
	if @all_midware.length() < 0 || @all_midware.length() > 0
    render :inline => %{
      <% grid            = build_all_midware_grid(@all_midware,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all midware errors' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
   else
      render :inline => %{
                    <% @content_header_caption = "'No errors found'"%>
            }, :layout => 'content'
   end
end

def view_all_midware_details
    id = params[:id]
	 if id && @all_midware_error = MidwareErrorLog.find(id)
		render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<%= view_all_midware_details_form(@all_midware_error,'view_paging_handler_all_midware')%>

		}, :layout => 'content'
     else
        render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<font color='blue'><b>record not found!</b></font>

		}, :layout => 'content'
	 end
end

def view_paging_handler_all_midware
    if params[:page]
  	   session[:midware_error_log_page] = params['page'] 
    end
    render_list_all_midware_errors
end

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                         END OF ALL MIDWARE ERRORS CODE
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



#================================================================================================
#                               goto date_time code
#================================================================================================

def goto_date_time
    return if authorise_for_web(program_name?,'read') == false
    
    @error_types =["palletizing","bintipping","carton labeling","rebin labeling","pdt","all midware errors","bad scans"]
    
    render :template=> '/diagnostics/midware/goto_date_time.rhtml', :layout=>'content'
    
end

def list_goto_date_time_errors
    @err_type = params[:error_type]
    
    @from_date = DateTime.civil(params[:from][:"view_from(1i)"].to_i, params[:from][:"view_from(2i)"].to_i, params[:from][:"view_from(3i)"].to_i, params[:from][:"view_from(4i)"].to_i, params[:from][:"view_from(5i)"].to_i).strftime("%Y/%m/%d %I:%M%p")
    
    @to_date = DateTime.civil(params[:to][:"view_to(1i)"].to_i, params[:to][:"view_to(2i)"].to_i, params[:to][:"view_to(3i)"].to_i, params[:to][:"view_to(4i)"].to_i, params[:to][:"view_to(5i)"].to_i).strftime("%Y/%m/%d %I:%M%p")
    
    if @err_type =="palletizing"
        if params[:page]!= nil 

     		session[:midware_error_log_page] = params['page']
    		 render_list_palletizing_errors
    
    		 return 
    	else
    		session[:midware_error_log_page] = nil
    	end
        
        list_query = "@midware_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
  	    @midware = MidwareErrorLog.find(:all, 
  	         :conditions =>['mw_type = ? and error_date_time > ? and error_date_time < ?', 'PALLETISING', '#{@from_date}', '#{@to_date}'],
  			 :limit => @midware_pages.items_per_page,
  			 :offset => @midware_pages.current.offset)"
    	session[:query] = list_query
    	render_list_palletizing_errors
    	
    elsif @err_type =="carton labeling"
        if params[:page]!= nil 

     		session[:midware_error_log_page] = params['page']
    		 render_list_carton_labeling_errors
    
    		 return 
    	else
    		session[:midware_error_log_page] = nil
    	end
        
        @type = "CARTON_LABELING"
        list_query = "@midware_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
	    @midware = MidwareErrorLog.find(:all, 
	         :conditions =>['mw_type = ? and error_date_time > ? and error_date_time < ?', '#{@type}', '#{@from_date}', '#{@to_date}'],
			 :limit => @midware_pages.items_per_page,
			 :offset => @midware_pages.current.offset)"
    	session[:query] = list_query
    	render_list_carton_labeling_errors
    
    elsif @err_type == "bintipping"
        if params[:page]!= nil 
    
     		session[:midware_error_log_page] = params['page']
    		 render_list_bintipping_errors
    
    		 return 
    	else
    		session[:midware_error_log_page] = nil
	    end
	    
        @type = 'BIN_TIPPING'
    
        list_query = "@midware_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
    	     @midware = MidwareErrorLog.find(:all,
    	         :conditions =>['mw_type = ? and error_description not like ? and error_date_time > ? and error_date_time < ?', '#{@type}', '%A valid bin was scanned to cancel the invalid bin%','#{@from_date}','#{@to_date}'],
    			 :limit => @midware_pages.items_per_page,
    			 :offset => @midware_pages.current.offset)"
    	session[:query] = list_query
    	
    	render_list_bintipping_errors
    
    elsif @err_type == "rebin labeling"
        if params[:page]!= nil 

     		session[:midware_error_log_page] = params['page']
    		 render_list_rebin_labeling
    
    		 return 
    	else
    		session[:midware_error_log_page] = nil
    	end
    	
        @type = 'REBIN_LABELING'

        list_query = "@rebin_labeling_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
    	  @rebin_labeling = MidwareErrorLog.find(:all, 
    	         :conditions =>['mw_type = ? and error_date_time > ? and error_date_time < ?', '#{@type}', '#{@from_date}', '#{@to_date}'],
    			 :limit => @rebin_labeling_pages.items_per_page,
    			 :offset => @rebin_labeling_pages.current.offset)"
    	session[:query] = list_query
    	render_list_rebin_labeling
    
    elsif @err_type == "pdt" 

     	if params[:page]!= nil 
    
     		session[:midware_error_log_page] = params['page']
    		 render_list_pdt_errors
    
    		 return 
    	else
    		session[:midware_error_log_page] = nil
    	end
    	
    	@type = 'PdtSymbol6800'
    
        list_query = "@pdt_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
    	  @pdt = MidwareErrorLog.find(:all, 
    	         :conditions =>['mw_type = ? and error_date_time > ? and error_date_time < ?', '#{@type}', '#{@from_date}', '#{@to_date}'],
    			 :limit => @pdt_pages.items_per_page,
    			 :offset => @pdt_pages.current.offset)"
    	session[:query] = list_query
    	render_list_pdt_errors
    
    elsif @err_type == "all midware errors"
        if params[:page]!= nil 

     		session[:midware_error_log_page] = params['page']
    		render_list_all_midware_errors
    
    		return 
    	else
    		session[:midware_error_log_page] = nil
    	end
    
        list_query = "@all_midware_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
    	  @all_midware = MidwareErrorLog.find(:all, 
    	         :conditions =>['error_date_time > ? and error_date_time < ?', '#{@from_date}', '#{@to_date}'],
    			 :limit => @all_midware_pages.items_per_page,
    			 :offset => @all_midware_pages.current.offset)"
    	session[:query] = list_query
    	render_list_all_midware_errors
    
    elsif @err_type == "bad scans"
        if params[:page]!= nil 

     		session[:midware_error_log_page] = params['page']
    		 render_list_bad_scans_errors
    
    		 return 
    	else
    		session[:midware_error_log_page] = nil
    	end
    	
    	@type = 'PALLETISING'
    
    #    list_query = "@badscans_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
    #	  @badscans = MidwareErrorLog.find(:all, 
    #	         :conditions =>['mw_type = ? and error_description like ? and error_date_time > ? and error_date_time < ?', 'PALLETISING', '%java.lang.NumberFormatException%', '#{@today}', '#{@tomorrow}'],
    #			 :limit => @badscans_pages.items_per_page,
    #			 :offset => @badscans_pages.current.offset)"
        list_query = "@badscans_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
    	  @badscans = MidwareErrorLog.find(:all, 
    	         :conditions =>['mw_type = ? and error_description like ? and error_date_time > ? and error_date_time < ?', '#{@type}', '%java.lang.NumberFormatException%', '#{@from_date}', '#{@to_date}'],
    	         :select =>'distinct short_description',
    			 :limit => @badscans_pages.items_per_page,
    			 :offset => @badscans_pages.current.offset)"
    	session[:query] = list_query
    	render_list_bad_scans_errors
    end
    
end

#================================================================================================
#                               End goto date_time code
#================================================================================================



end
