class  Fg::VoyagePortTypeController < ApplicationController
 
def program_name?
	"voyage_port_type"
end

def bypass_generic_security?
	true
end
def list_voyage_port_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:voyage_port_types_page] = params['page']

		 render_list_voyage_port_types

		 return 
	else
		session[:voyage_port_types_page] = nil
	end

	list_query = "@voyage_port_type_pages = Paginator.new self, VoyagePortType.count, @@page_size,@current_page
	 @voyage_port_types = VoyagePortType.find(:all,
				 :limit => @voyage_port_type_pages.items_per_page,
				 :offset => @voyage_port_type_pages.current.offset)"
	session[:query] = list_query
	render_list_voyage_port_types
end


def render_list_voyage_port_types
	@pagination_server = "list_voyage_port_types"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:voyage_port_types_page]
	@current_page = params['page']||= session[:voyage_port_types_page]
	@voyage_port_types =  eval(session[:query]) if !@voyage_port_types
	render :inline => %{
      <% grid            = build_voyage_port_type_grid(@voyage_port_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all voyage_port_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@voyage_port_type_pages) if @voyage_port_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_voyage_port_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_voyage_port_type_search_form
end

def search_voyage_port_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true
	render_voyage_port_type_search_form
end

def render_voyage_port_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  voyage_port_types'"%> 

		<%= build_voyage_port_type_search_form(nil,'submit_voyage_port_types_search','submit_voyage_port_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_voyage_port_types_search
	@voyage_port_types = dynamic_search(params[:voyage_port_type] ,'voyage_port_types','VoyagePortType')
	if @voyage_port_types.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_voyage_port_type_search_form
		else
			render_list_voyage_port_types
	end
end

 
def delete_voyage_port_type
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:voyage_port_types_page] = params['page']
		render_list_voyage_port_types
		return
	end
	id = params[:id]
	if id && voyage_port_type = VoyagePortType.find(id)
		voyage_port_type.destroy
		session[:alert] = " Record deleted."
		render_list_voyage_port_types
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_voyage_port_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_voyage_port_type
end
 
def create_voyage_port_type
 begin
	 @voyage_port_type = VoyagePortType.new(params[:voyage_port_type])
	 if @voyage_port_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_voyage_port_type
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_voyage_port_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new voyage_port_type'"%> 

		<%= build_voyage_port_type_form(@voyage_port_type,'create_voyage_port_type','create_voyage_port_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_voyage_port_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @voyage_port_type = VoyagePortType.find(id)
		render_edit_voyage_port_type

	 end
end


def render_edit_voyage_port_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit voyage_port_type'"%> 

		<%= build_voyage_port_type_form(@voyage_port_type,'update_voyage_port_type','update_voyage_port_type',true)%>

		}, :layout => 'content'
end
 
def update_voyage_port_type
 begin

	 id = params[:voyage_port_type][:id]
	 if id && @voyage_port_type = VoyagePortType.find(id)
		 if @voyage_port_type.update_attributes(params[:voyage_port_type])
			@voyage_port_types = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_voyage_port_types
	 else
			 render_edit_voyage_port_type

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
