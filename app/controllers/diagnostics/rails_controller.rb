class Diagnostics::RailsController < ApplicationController
    
def program_name?
	"rails"
end

def bypass_generic_security?
	true
end   

#=============================================================
#                 Last  n errors
#=============================================================

def last_n_errors
    return if authorise_for_web(program_name?,'read') == false
    
    render :template=>'/diagnostics/rails/last_n_errors.rhtml', :layout=>'content'
end

def list_last_n_errors
    @limit = params[:error_limit]
    if @limit == nil || @limit ==""
        @error_limit = 10
    else
        @error_limit = @limit.to_i
    end
    #@error_limit = @limit.to_i
    if @error_limit.integer?
        if (@error_limit.to_i == 0)
            render :inline=> %{
                  <% @content_header_caption ="'Enter number greater than zero'" %>
                  <font size='3px' color='red'><b>ERROR</b></font>
                  (<b>enter a number greater than zero</b>)
            }, :layout=>'content'
        elsif(@error_limit.to_i < 0)
            render :inline=> %{
                  <% @content_header_caption ="'Enter a non-negative number greater than zero'" %>
                  <font size='3px' color='red'><b>ERROR</b></font>
                  (<b>enter a non-negative number greater than zero</b>)
            }, :layout=>'content'
        else
            if params[:page]!= nil 

         		session[:rails_error_page] = params['page']
        		 render_list_rails_errors
        
        		 return 
        	else
        		session[:rails_error_page] = nil
        	end
        	
        	t1 = Date.today
        	t2 = Date.today + 1
        	@today = t1.strftime("%Y-%m-%d")
        	@tomorrow = t2.strftime("%Y-%m-%d")
        	@error_type = 'outbox_processor'
        	
        	list_query ="@rails = RailsError.find(:all,
  	                         :conditions=>['error_type != ? and created_on > ? and created_on < ?', '#{@error_type}', '#{@today}', '#{@tomorrow}'],
  	                         :limit=> '#{@error_limit}')"
  	        session[:query] = list_query
  	        render_list_rails_errors
        	
        end
    else
        render :inline=> %{
                  <% @content_header_caption ="'Enter number greater than zero'" %>
                  <font size='3px' color='red'><b>ERROR</b></font>
                  (<b>enter a number greater than zero</b>)
            }, :layout=>'content'
    end
end

#=============================================================
#                End of Last  n errors
#=============================================================




#==========================================================================
#         Shared methods
#==========================================================================


  def render_list_rails_errors
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:rails_error_page] if session[:rails_error_page]

    @current_page = params['page'] if params['page']

    @rails =  eval(session[:query]) if !@rails

    render :inline => %{
          <% grid            = build_rails_grid(@rails,@can_edit,@can_delete)%>
          <% grid.caption    = 'list of rails errors' %>
          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
    }, :layout => 'content'
  end


def view_details
    id = params[:id]
	 if id && @rails_error = RailsError.find(id)
		render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<%= view_rails_error_details_form(@rails_error,'view_paging_handler_rails')%>

		}, :layout => 'content'

	 end
end

def view_paging_handler_rails
    if params[:page]
  	   session[:midware_error_log_page] = params['page'] 
  	   #@bin_tipping = eval(session[:query]) 
    end
    render_list_rails_errors 
end

#==========================================================================
#        End of  Shared methods
#==========================================================================



#=============================================================
#                 Errors by User
#=============================================================

def errors_by_user
    return if authorise_for_web(program_name?,'read') == false
    
    @usernames = User.find_by_sql("select distinct user_name from users order by user_name asc")
   
    @list = Array.new
    
    if @usernames!=nil
        @usernames.each do |name|
            @list.push(name.user_name)
        end
        @list.push("system")
    else
        @list.push("system")
    end
    
    render :template=>'/diagnostics/rails/errors_by_user.rhtml', :layout=>'content'
end

def list_errors_by_user
    @user = params[:username]
    
    if params[:page]!= nil 

 		session[:rails_error_page] = params['page']
		 render_list_rails_errors

		 return 
	else
		session[:rails_error_page] = nil
	end
	
	t1 = Date.today
	t2 = Date.today + 1
	@today = t1.strftime("%Y-%m-%d")
	@tomorrow = t2.strftime("%Y-%m-%d")
	@error_type = 'outbox_processor'
	
	list_query ="@rails = RailsError.find(:all,
                     :conditions=>['error_type != ? and created_on > ? and created_on < ? and logged_on_user = ?', '#{@error_type}', '#{@today}', '#{@tomorrow}', '#{@user}'])"
    session[:query] = list_query
    render_list_rails_errors
end

#=============================================================
#                 End of Errors by User
#=============================================================




#=============================================================
#                 Last  10 errors
#=============================================================

def last_10_errors
    if params[:page]!= nil 

 		session[:rails_error_page] = params['page']
		 render_list_rails_errors

		 return 
	else
		session[:rails_error_page] = nil
	end
	
	t1 = Date.today
	t2 = Date.today + 1
	@today = t1.strftime("%Y-%m-%d")
	@tomorrow = t2.strftime("%Y-%m-%d")
	@error_type = 'outbox_processor'
	
	list_query ="@rails = RailsError.find(:all,
                     :conditions=>['error_type != ? and created_on > ? and created_on < ?', '#{@error_type}', '#{@today}', '#{@tomorrow}'],
                     :limit=>10,:order => 'id desc')"
    session[:query] = list_query
    render_list_rails_errors
end

#=============================================================
#                 End of Last  10 errors
#=============================================================




#=============================================================
#                 Errors for Today
#=============================================================

def errors_today
    if params[:page]!= nil 

 		session[:rails_error_page] = params['page']
		 render_list_rails_errors

		 return 
	else
		session[:rails_error_page] = nil
	end
	
	t1 = Date.today
	t2 = Date.today + 1
	@today = t1.strftime("%Y-%m-%d")
	@tomorrow = t2.strftime("%Y-%m-%d")
	@error_type = 'outbox_processor'
	
	list_query ="@rails = RailsError.find(:all,
                     :conditions=>['error_type != ? and created_on > ? and created_on < ?', '#{@error_type}', '#{@today}', '#{@tomorrow}'])"
    session[:query] = list_query
    render_list_rails_errors
end

#=============================================================
#                 End Errors for Today
#=============================================================




#=============================================================
#                 Last hour errors
#=============================================================

def list_last_hour_errors
    if params[:page]!= nil 

 		session[:rails_error_page] = params['page']
		 render_list_rails_errors

		 return 
	else
		session[:rails_error_page] = nil
	end
	

	@last_hour = 1.hour.ago.to_formatted_s(:db)
	

	
	@error_type = 'outbox_processor'
	
	list_query ="@rails = RailsError.find(:all,
                     :conditions=>['error_type != ? and created_on > ?', '#{@error_type}', '#{@last_hour}'])"
    session[:query] = list_query
    render_list_rails_errors
end


#=============================================================
#                 End Last hour errors
#=============================================================




#=============================================================
#                 Custom Time Search code
#=============================================================

def custom_time_search
    return if authorise_for_web(program_name?,'read') == false
    
    render :template=> '/diagnostics/rails/custom_time_search.rhtml', :layout=>'content'
end


def list_custom_time_search_errors
    
    @from_date = DateTime.civil(params[:from][:"view_from(1i)"].to_i, params[:from][:"view_from(2i)"].to_i, params[:from][:"view_from(3i)"].to_i, params[:from][:"view_from(4i)"].to_i, params[:from][:"view_from(5i)"].to_i).strftime("%Y-%m-%d %I:%M%p")
    
    @to_date = DateTime.civil(params[:to][:"view_to(1i)"].to_i, params[:to][:"view_to(2i)"].to_i, params[:to][:"view_to(3i)"].to_i, params[:to][:"view_to(4i)"].to_i, params[:to][:"view_to(5i)"].to_i).strftime("%Y-%m-%d %I:%M%p")
    
    if params[:page]!= nil 

 		session[:rails_error_page] = params['page']
		 render_list_rails_errors

		 return 
	else
		session[:rails_error_page] = nil
	end
	


	
	@error_type = 'outbox_processor'
	
	list_query ="@rails = RailsError.find(:all,
                     :conditions=>['error_type != ? and created_on > ? and created_on < ?', '#{@error_type}', '#{@from_date}', '#{@to_date}'])"
    session[:query] = list_query
    render_list_rails_errors
end

#=============================================================
#                 End Custom Time Search code
#=============================================================




end
