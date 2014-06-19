class  Fg::PortController < ApplicationController
 
def program_name?
	"port"
end

def bypass_generic_security?
	true
end
def list_ports
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:ports_page] = params['page']

		 render_list_ports

		 return 
	else
		session[:ports_page] = nil
	end

	list_query = "@port_pages = Paginator.new self, Port.count, @@page_size,@current_page
	 @ports = Port.find(:all,
				 :limit => @port_pages.items_per_page,
				 :offset => @port_pages.current.offset)"
	session[:query] = list_query
	render_list_ports
end


def render_list_ports
	@pagination_server = "list_ports"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:ports_page]
	@current_page = params['page']||= session[:ports_page]
	@ports =  eval(session[:query]) if !@ports
	render :inline => %{
      <% grid            = build_port_grid(@ports,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all ports' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@port_pages) if @port_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_ports_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_port_search_form
end

def render_port_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  ports'"%> 

		<%= build_port_search_form(nil,'submit_ports_search','submit_ports_search',@is_flat_search)%>

		}, :layout => 'content'
end

def search_ports_hierarchy
	return if authorise_for_web(program_name?,'read')== false

	@is_flat_search = false
	render_port_search_form(true)
end



 
def submit_ports_search
	@ports = dynamic_search(params[:port] ,'ports','Port')
	if @ports.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_port_search_form
		else
			render_list_ports
	end
end

 
def delete_port
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:ports_page] = params['page']
		render_list_ports
		return
	end
	id = params[:id]
	if id && port = Port.find(id)
		port.destroy
		session[:alert] = " Record deleted."
		render_list_ports
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_port
	return if authorise_for_web(program_name?,'create')== false
		render_new_port
end
 
def create_port
 begin
	 @port = Port.new(params[:port])
	 if @port.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_port
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_port
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new port'"%> 

		<%= build_port_form(@port,'create_port','create_port',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_port
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @port = Port.find(id)
		render_edit_port

	 end
end


def render_edit_port
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit port'"%> 

		<%= build_port_form(@port,'update_port','update_port',true)%>

		}, :layout => 'content'
end
 
def update_port
 begin

	 id = params[:port][:id]
	 if id && @port = Port.find(id)
		 if @port.update_attributes(params[:port])
			@ports = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_ports
	 else
			 render_edit_port

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
