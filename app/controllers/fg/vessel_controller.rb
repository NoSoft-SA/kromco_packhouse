class  Fg::VesselController < ApplicationController
 
def program_name?
	"vessel"
end

def bypass_generic_security?
	true
end
def list_vessels
	return if authorise_for_web(program_name?,'read') == false 
    	if params[:page]!= nil
     		session[:vessels_page] = params['page']
    		 render_list_vessels
    		 return
	else
		session[:vessels_page] = nil
	end
    	list_query = "@vessel_pages = Paginator.new self, Vessel.count, @@page_size,@current_page
	 @vessels = Vessel.find(:all,
				 :limit => @vessel_pages.items_per_page,
				 :offset => @vessel_pages.current.offset)"
	session[:query] = list_query
	render_list_vessels
end


def render_list_vessels
	@pagination_server = "list_vessels"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:vessels_page]
	@current_page = params['page']||= session[:vessels_page]
	@vessels =  eval(session[:query]) if !@vessels
	render :inline => %{
      <% grid            = build_vessel_grid(@vessels,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all vessels' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@vessel_pages) if @vessel_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_vessels_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_vessel_search_form
end

def search_vessels_hierarchy
	return if authorise_for_web(program_name?,'read')== false

	@is_flat_search = false
	render_vessel_search_form
end






def render_vessel_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  vessels'"%> 

		<%= build_vessel_search_form(nil,'submit_vessels_search','submit_vessels_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_vessels_search
	@vessels = dynamic_search(params[:vessel] ,'vessels','Vessel')
	if @vessels.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_vessel_search_form
		else
			render_list_vessels
	end
end

 
def delete_vessel
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:vessels_page] = params['page']
		 
		return
	end
	id = params[:id]
	if id && vessel = Vessel.find(id)
		vessel.destroy
		session[:alert] = " Record deleted."
		render_list_vessels
	end
 rescue
   handle_error('record could not be deleted')
end
end
 
def new_vessel
	return if authorise_for_web(program_name?,'create')== false
		render_new_vessel
end
 
def create_vessel
 begin
	 @vessel = Vessel.new(params[:vessel])
	 if @vessel.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_vessel
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_vessel
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new vessel'"%> 

		<%= build_vessel_form(@vessel,'create_vessel','create_vessel',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_vessel
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @vessel = Vessel.find(id)
		render_edit_vessel

	 end
end


def render_edit_vessel
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit vessel'"%> 

		<%= build_vessel_form(@vessel,'update_vessel','update_vessel',true)%>

		}, :layout => 'content'
end
 
def update_vessel
 begin

	 id = params[:vessel][:id]
	 if id && @vessel = Vessel.find(id)
		 if @vessel.update_attributes(params[:vessel])
			@vessels = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_vessels
	 else
			 render_edit_vessel

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
