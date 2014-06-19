class PartyManager::MessagesController < ApplicationController

	 layout "content"
	 
def program_name?
	"messages"  		
end

  

  def save_dept_message
  
    dept_name = params[:message][:department]
    if dept_name == ""
     flash[:error]= ("NO DEPARTMENT SPECIFIED")
     set_department_message
     return
    end
    msg =  params[:message][:message_body]
    dept  = Department.find_by_department_name(dept_name)
    dept.department_message = DepartmentMessage.new if !dept.department_message
    dept.department_message.message_body = msg
    dept.department_message.created_by = session[:user_id].id
    dept.department_message.save
    redirect_to_index("message saved")
    
  end
  
   def set_company_message
   
    @message = CompanyMessage.find_by_id(1)
    
    
     render :inline => %{
		<% @content_header_caption = "'set company message'" %> 

		<%= build_message_form(@message,'save_company_message','message_body')%>

		}, :layout => 'content'
  
  end
   
   def save_company_message
  
     comp_msg = CompanyMessage.find_by_id(1)
     comp_msg = CompanyMessage.new if !comp_msg
     msg =  params[:message][:message_body]
     comp_msg.message_body = msg
     comp_msg.created_by = session[:user_id].id
     comp_msg.save
     redirect_to_index("message saved")
    
  end

  def set_department_message
     render :inline => %{
		<% @content_header_caption = "'set departmental message'" %> 

		<%= build_message_form(nil,'save_dept_message','message_body',true)%>

		}, :layout => 'content'
  
  end
  
  def department_changed
    department = get_selected_combo_value(params)
    
    @message = nil
    @message = Department.find_by_department_name(department).department_message if department != ""
    
   
    render :inline => %{
		<%= text_area('message', 'message_body',{:cols => 40,:rows => 10})%>

		}
    
  
  end

 def find_user
    render :inline => %{
		<% @content_header_caption = "'find user'"%> 

		<%= build_user_search_form(nil,'list_users','save')%>

		}, :layout => 'content'

  end
  
  def save_user_message
 
   message = session[:message_user].user_message if session[:message_user].user_message
   message = UserMessage.new if !message
   
   message.message_body = params[:message][:message_body]
   message.user = session[:message_user]
   message.created_by = session[:user_id].id
   message.save
   redirect_to_index("message saved")
  
  end
  
  
  def set_user_message
    
    @user = User.find(params[:id])
    @message = @user.user_message
    puts "msg user is: " + @user.id.to_s
    session[:message_user]= @user
    render :inline => %{
		<% @content_header_caption = "'set message for user " + @user.user_name + "'" %> 

		<%= build_message_form(@message,'save_user_message','message_body')%>

		}, :layout => 'content'
  
  end
  

  def list_users
  
    @users = dynamic_search(params[:user] ,'users','User',true, nil,'user_name')
    render :inline => %{
      <% grid            = get_users_grid(@users) %>
      <% grid.caption    = 'list of found users for the query' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  
  end
  
  
  #	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(users)
#	-----------------------------------------------------------------------------------------------------------
def user_department_name_search_combo_changed
	department_name = get_selected_combo_value(params)
	session[:user_search_form][:department_name_combo_selection] = department_name
	@last_names = User.find_by_sql("Select distinct last_name from users where department_name = '#{department_name}'").map{|g|[g.last_name]}
	@last_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('user','last_name',@last_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_user_last_name'/>
		<%= observe_field('user_last_name',:update => 'first_name_cell',:url => {:action => session[:user_search_form][:last_name_observer][:remote_method]},:loading => "show_element('img_user_last_name');",:complete => session[:user_search_form][:last_name_observer][:on_completed_js])%>
		}

end


def user_last_name_search_combo_changed
	last_name = get_selected_combo_value(params)
	session[:user_search_form][:last_name_combo_selection] = last_name
	department_name = 	session[:user_search_form][:department_name_combo_selection]
	@first_names = User.find_by_sql("Select distinct first_name from users where last_name = '#{last_name}' and department_name = '#{department_name}'").map{|g|[g.first_name]}
	@first_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('user','first_name',@first_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_user_first_name'/>
		<%= observe_field('user_first_name',:update => 'user_name_cell',:url => {:action => session[:user_search_form][:first_name_observer][:remote_method]},:loading => "show_element('img_user_first_name');",:complete => session[:user_search_form][:first_name_observer][:on_completed_js])%>
		}

end


def user_first_name_search_combo_changed
	first_name = get_selected_combo_value(params)
	session[:user_search_form][:first_name_combo_selection] = first_name
	last_name = 	session[:user_search_form][:last_name_combo_selection]
	department_name = 	session[:user_search_form][:department_name_combo_selection]
	@user_names = User.find_by_sql("Select distinct user_name from users where first_name = '#{first_name}' and last_name = '#{last_name}' and department_name = '#{department_name}'").map{|g|[g.user_name]}
	@user_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('user','user_name',@user_names)%>

		}

end

end
