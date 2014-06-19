class  Security::UserController < ApplicationController
 
def program_name?
	"user"
end

def bypass_generic_security?
	true
end
def list_users
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:users_page] = params['page']

		 render_list_users

		 return 
	else
		session[:users_page] = nil
	end

	list_query = "@user_pages = Paginator.new self, User.count, @@page_size,@current_page
	 @users = User.find(:all,
				 :limit => @user_pages.items_per_page,
				 :offset => @user_pages.current.offset)"
	session[:query] = list_query
	render_list_users
end


def render_list_users
	@pagination_server = "list_users"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:users_page]
	@current_page = params['page']||= session[:users_page]
	@users =  eval(session[:query]) if !@users
	render :inline => %{
		<% grid = build_user_grid(@users,@can_edit,@can_delete)%>
		<% grid.caption = 'list of all users'%>
		<% @header_content = grid.build_grid_data %>

		<% @pagination = pagination_links(@user_pages) if @user_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_users_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_user_search_form
end

def render_user_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  users'"%> 

		<%= build_user_search_form(nil,'submit_users_search','submit_users_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_users_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_user_search_form(true)
end

 
def submit_users_search
	@users = dynamic_search(params[:user] ,'users','User')
	if @users.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_user_search_form
		else
			render_list_users
	end
end

 
def delete_user
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:users_page] = params['page']
		render_list_users
		return
	end
	id = params[:id]
	if id && user = User.find(id)
		user.destroy
		session[:alert] = ' Record deleted.'
		render_list_users
	end
	rescue
		handle_error('record could not be deleted')
end
 
def new_user
	return if authorise_for_web(program_name?,'create')== false
		render_new_user
end
 
def create_user
	 @user = User.new(params[:user])
	 if @user.save
		 redirect_to_index("new record created successfully","'create successful'")
	else
		@is_create_retry = true
		render_new_user
	 end
rescue
	 handle_error('record could not be created')
end

def render_new_user
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new user'"%> 

		<%= build_user_form(@user,'create_user','create_user',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_user
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @user = User.find(id)
		render_edit_user

	 end
end


def render_edit_user
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit user'"%> 

		<%= build_user_form(@user,'update_user','update_user',true)%>

		}, :layout => 'content'
end
 
def update_user
	 id = params[:user][:id]
	 if id && @user = User.find(id)
		 if @user.update_attributes(params[:user])
			@users = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_users
	 else
			 render_edit_user
		 end
	 end
rescue
	 handle_error('record could not be saved')
 end
 
  def search_dm_users
    return if authorise_for_web(program_name?,'read')== false
    dm_session['se_layout']              = 'content'
    @content_header_caption              = "'Search Users'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form('search_users.yml', 'search_dm_users_grid')
  end

 
  def search_dm_users_grid
    @users = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @can_edit        = authorise(program_name?, 'edit', session[:user_id])
    @can_delete      = authorise(program_name?, 'delete', session[:user_id])
    @stat            = dm_session[:search_engine_query_definition]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]

    render :inline => %{
      <% grid            = build_user_dm_grid(@users, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
      <% grid.caption    = 'Users' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end

 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: person_id
#	---------------------------------------------------------------------------------
def user_first_name_changed
	first_name = get_selected_combo_value(params)
	session[:user_form][:first_name_combo_selection] = first_name
	@last_names = User.last_names_for_first_name(first_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('user','last_name',@last_names)%>

		}

end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: department_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(users)
#	-----------------------------------------------------------------------------------------------------------

end
