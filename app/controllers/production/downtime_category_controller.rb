class  Production::DowntimeCategoryController < ApplicationController
 
def program_name?
	"downtime_category"
end

def bypass_generic_security?
	true
end
def list_downtime_categories
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:downtime_categories_page] = params['page']

		 render_list_downtime_categories

		 return 
	else
		session[:downtime_categories_page] = nil
	end

	list_query = "@downtime_category_pages = Paginator.new self, DowntimeCategory.count, @@page_size,@current_page
	 @downtime_categories = DowntimeCategory.find(:all,
				 :limit => @downtime_category_pages.items_per_page,
				 :offset => @downtime_category_pages.current.offset)"
	session[:query] = list_query
	render_list_downtime_categories
end


def render_list_downtime_categories
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:downtime_categories_page] if session[:downtime_categories_page]
	@current_page = params['page'] if params['page']
	@downtime_categories =  eval(session[:query]) if !@downtime_categories
	render :inline => %{
      <% grid            = build_downtime_category_grid(@downtime_categories,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all downtime_categories' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@downtime_category_pages) if @downtime_category_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_downtime_categories_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_downtime_category_search_form
end

def render_downtime_category_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  downtime_categories'"%> 

		<%= build_downtime_category_search_form(nil,'submit_downtime_categories_search','submit_downtime_categories_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_downtime_categories_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_downtime_category_search_form(true)
end

def render_downtime_category_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  downtime_categories'"%> 

		<%= build_downtime_category_search_form(nil,'submit_downtime_categories_search','submit_downtime_categories_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_downtime_categories_search
	if params['page']
		session[:downtime_categories_page] =params['page']
	else
		session[:downtime_categories_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @downtime_categories = dynamic_search(params[:downtime_category] ,'downtime_categories','DowntimeCategory')
	else
		@downtime_categories = eval(session[:query])
	end
	if @downtime_categories.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_downtime_category_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_downtime_categories
		end

	else

		render_list_downtime_categories
	end
end

 
def delete_downtime_category
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:downtime_categories_page] = params['page']
		render_list_downtime_categories
		return
	end
	id = params[:id]
	if id && downtime_category = DowntimeCategory.find(id)
		downtime_category.destroy
		session[:alert] = " Record deleted."
		render_list_downtime_categories
	end
end
 
def new_downtime_category
	return if authorise_for_web(program_name?,'create')== false
		render_new_downtime_category
end
 
def create_downtime_category
	 @downtime_category = DowntimeCategory.new(params[:downtime_category])
	 if @downtime_category.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_downtime_category
	 end
end

def render_new_downtime_category
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new downtime_category'"%> 

		<%= build_downtime_category_form(@downtime_category,'create_downtime_category','create_downtime_category',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_downtime_category
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @downtime_category = DowntimeCategory.find(id)
		render_edit_downtime_category

	 end
end


def render_edit_downtime_category
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit downtime_category'"%> 

		<%= build_downtime_category_form(@downtime_category,'update_downtime_category','update_downtime_category',true)%>

		}, :layout => 'content'
end
 
def update_downtime_category
	if params[:page]
		session[:downtime_categories_page] = params['page']
		render_list_downtime_categories
		return
	end

		@current_page = session[:downtime_categories_page]
	 id = params[:downtime_category][:id]
	 if id && @downtime_category = DowntimeCategory.find(id)
		 if @downtime_category.update_attributes(params[:downtime_category])
			@downtime_categories = eval(session[:query])
			render_list_downtime_categories
	 else
			 render_edit_downtime_category

		 end
	 end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(downtime_categories)
#	-----------------------------------------------------------------------------------------------------------

end
