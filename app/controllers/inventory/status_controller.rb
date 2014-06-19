class  Inventory::StatusController < ApplicationController
 
def program_name?
	"status"
end

def bypass_generic_security?
	true
end
def list_statuses
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:statuses_page] = params['page']

		 render_list_statuses

		 return 
	else
		session[:statuses_page] = nil
	end

	list_query = "@status_pages = Paginator.new self, Status.count, @@page_size,@current_page
	 @statuses = Status.find(:all,
				 :limit => @status_pages.items_per_page,
				 :offset => @status_pages.current.offset)"
	session[:query] = list_query
	render_list_statuses
end


def render_list_statuses
	@pagination_server = "list_statuses"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:statuses_page]
	@current_page = params['page']||= session[:statuses_page]
	@statuses =  eval(session[:query]) if !@statuses
	render :inline => %{
      <% grid            = build_status_grid(@statuses,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all statuses' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@status_pages) if @status_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_statuses_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_status_search_form
end

def render_status_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  statuses'"%> 

		<%= build_status_search_form(nil,'submit_statuses_search','submit_statuses_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_statuses_search
	@statuses = dynamic_search(params[:status] ,'statuses','Status')
	if @statuses.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_status_search_form
		else
			render_list_statuses
	end
end

 
def delete_status
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:statuses_page] = params['page']
		render_list_statuses
		return
	end
	id = params[:id]
	if id && status = Status.find(id)
		status.destroy
		session[:alert] = " Record deleted."
		render_list_statuses
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_status
	return if authorise_for_web(program_name?,'create')== false
		render_new_status
end
 
def create_status
 begin
	 @status = Status.new(params[:status])
	 if @status.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_status
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_status
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new status'"%> 

		<%= build_status_form(@status,'create_status','create_status',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_status
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @status = Status.find(id)
		render_edit_status

	 end
end


def render_edit_status
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit status'"%> 

		<%= build_status_form(@status,'update_status','update_status',true)%>

		}, :layout => 'content'
end
 
def update_status
 begin

	 id = params[:status][:id]
	 if id && @status = Status.find(id)
		 if @status.update_attributes(params[:status])
			@statuses = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_statuses
	 else
			 render_edit_status

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
