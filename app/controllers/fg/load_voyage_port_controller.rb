class  Fg::LoadVoyagePortController < ApplicationController
 
def program_name?
	"load_voyage_port"
end

def bypass_generic_security?
	true
end
def list_load_voyage_ports
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:load_voyage_ports_page] = params['page']

		 render_list_load_voyage_ports

		 return 
	else
		session[:load_voyage_ports_page] = nil
	end

	list_query = "@load_voyage_port_pages = Paginator.new self, LoadVoyagePort.count, @@page_size,@current_page
	 @load_voyage_ports = LoadVoyagePort.find(:all,
				 :limit => @load_voyage_port_pages.items_per_page,
				 :offset => @load_voyage_port_pages.current.offset)"
	session[:query] = list_query
	render_list_load_voyage_ports
end


def render_list_load_voyage_ports
	@pagination_server = "list_load_voyage_ports"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:load_voyage_ports_page]
	@current_page = params['page']||= session[:load_voyage_ports_page]
	@load_voyage_ports =  eval(session[:query]) if !@load_voyage_ports
	render :inline => %{
      <% grid            = build_load_voyage_port_grid(@load_voyage_ports,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all load_voyage_ports' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@load_voyage_port_pages) if @load_voyage_port_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_load_voyage_ports_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_load_voyage_port_search_form
end

def render_load_voyage_port_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  load_voyage_ports'"%> 

		<%= build_load_voyage_port_search_form(nil,'submit_load_voyage_ports_search','submit_load_voyage_ports_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_load_voyage_ports_search
	@load_voyage_ports = dynamic_search(params[:load_voyage_port] ,'load_voyage_ports','LoadVoyagePort')
	if @load_voyage_ports.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_load_voyage_port_search_form
		else
			render_list_load_voyage_ports
	end
end

 
def delete_load_voyage_port
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:load_voyage_ports_page] = params['page']
		render_list_load_voyage_ports
		return
	end
	id = params[:id]
	if id && load_voyage_port = LoadVoyagePort.find(id)
		load_voyage_port.destroy
		session[:alert] = " Record deleted."
		render_list_load_voyage_ports
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_load_voyage_port
	return if authorise_for_web(program_name?,'create')== false
		render_new_load_voyage_port
end
 
def create_load_voyage_port
 begin
	 @load_voyage_port = LoadVoyagePort.new(params[:load_voyage_port])
	 if @load_voyage_port.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_load_voyage_port
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_load_voyage_port
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new load_voyage_port'"%> 

		<%= build_load_voyage_port_form(@load_voyage_port,'create_load_voyage_port','create_load_voyage_port',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_load_voyage_port
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @load_voyage_port = LoadVoyagePort.find(id)
		render_edit_load_voyage_port

	 end
end


def render_edit_load_voyage_port
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit load_voyage_port'"%> 

		<%= build_load_voyage_port_form(@load_voyage_port,'update_load_voyage_port','update_load_voyage_port',true)%>

		}, :layout => 'content'
end
 
def update_load_voyage_port
 begin

	 id = params[:load_voyage_port][:id]
	 if id && @load_voyage_port = LoadVoyagePort.find(id)
		 if @load_voyage_port.update_attributes(params[:load_voyage_port])
			@load_voyage_ports = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_load_voyage_ports
	 else
			 render_edit_load_voyage_port

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: load_voyages_id
#	---------------------------------------------------------------------------------
 

end
