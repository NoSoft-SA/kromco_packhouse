class  QualityControl::MrlLabelTypeController < ApplicationController
 
def program_name?
	"mrl_label_type"
end

def bypass_generic_security?
	true
end
def list_mrl_label_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:mrl_label_types_page] = params['page']

		 render_list_mrl_label_types

		 return 
	else
		session[:mrl_label_types_page] = nil
	end

	list_query = "@mrl_label_type_pages = Paginator.new self, MrlLabelType.count, @@page_size,@current_page
	 @mrl_label_types = MrlLabelType.find(:all,
				 :limit => @mrl_label_type_pages.items_per_page,
				 :offset => @mrl_label_type_pages.current.offset)"
	session[:query] = list_query
	render_list_mrl_label_types
end


def render_list_mrl_label_types
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:mrl_label_types_page] if session[:mrl_label_types_page]
	@current_page = params['page'] if params['page']
	@mrl_label_types =  eval(session[:query]) if !@mrl_label_types
	render :inline => %{
      <% grid            = build_mrl_label_type_grid(@mrl_label_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all mrl_label_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@mrl_label_type_pages) if @mrl_label_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_mrl_label_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_mrl_label_type_search_form
end

def render_mrl_label_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  mrl_label_types'"%> 

		<%= build_mrl_label_type_search_form(nil,'submit_mrl_label_types_search','submit_mrl_label_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_mrl_label_types_search
	if params['page']
		session[:mrl_label_types_page] =params['page']
	else
		session[:mrl_label_types_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @mrl_label_types = dynamic_search(params[:mrl_label_type] ,'mrl_label_types','MrlLabelType')
	else
		@mrl_label_types = eval(session[:query])
	end
	if @mrl_label_types.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_mrl_label_type_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_mrl_label_types
		end

	else

		render_list_mrl_label_types
	end
end

 
def delete_mrl_label_type
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:mrl_label_types_page] = params['page']
		render_list_mrl_label_types
		return
	end
	id = params[:id]
	if id && mrl_label_type = MrlLabelType.find(id)
		mrl_label_type.destroy
		session[:alert] = " Record deleted."
		render_list_mrl_label_types
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_mrl_label_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_mrl_label_type
end
 
def create_mrl_label_type
 begin
	 @mrl_label_type = MrlLabelType.new(params[:mrl_label_type])
	 if @mrl_label_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_mrl_label_type
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_mrl_label_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new mrl_label_type'"%> 

		<%= build_mrl_label_type_form(@mrl_label_type,'create_mrl_label_type','create_mrl_label_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_mrl_label_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @mrl_label_type = MrlLabelType.find(id)
		render_edit_mrl_label_type

	 end
end


def render_edit_mrl_label_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit mrl_label_type'"%> 

		<%= build_mrl_label_type_form(@mrl_label_type,'update_mrl_label_type','update_mrl_label_type',true)%>

		}, :layout => 'content'
end
 
def update_mrl_label_type
 begin

	if params[:page]
		session[:mrl_label_types_page] = params['page']
		render_list_mrl_label_types
		return
	end

		@current_page = session[:mrl_label_types_page]
	 id = params[:mrl_label_type][:id]
	 if id && @mrl_label_type = MrlLabelType.find(id)
		 if @mrl_label_type.update_attributes(params[:mrl_label_type])
			@mrl_label_types = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_mrl_label_types
	 else
			 render_edit_mrl_label_type

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
