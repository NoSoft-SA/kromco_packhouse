class  RawMaterials::ProductClassController < ApplicationController
 
def program_name?
	"product_class"
end

def bypass_generic_security?
	true
end
def list_product_classes
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:product_classes_page] = params['page']

		 render_list_product_classes

		 return 
	else
		session[:product_classes_page] = nil
	end

	list_query = "@product_class_pages = Paginator.new self, ProductClass.count, @@page_size,@current_page
	 @product_classes = ProductClass.find(:all,
				 :limit => @product_class_pages.items_per_page,
				 :offset => @product_class_pages.current.offset)"
	session[:query] = list_query
	render_list_product_classes
end


def render_list_product_classes
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:product_classes_page] if session[:product_classes_page]
	@current_page = params['page'] if params['page']
	@product_classes =  eval(session[:query]) if !@product_classes
	render :inline => %{
      <% grid            = build_product_class_grid(@product_classes,@can_edit,@can_delete) %>
      <% grid.caption    = 'List of all product_classes' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@product_class_pages) if @product_class_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_product_classes_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_product_class_search_form
end

def render_product_class_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  product_classes'"%> 

		<%= build_product_class_search_form(nil,'submit_product_classes_search','submit_product_classes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_product_classes_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_product_class_search_form(true)
end

def render_product_class_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  product_classes'"%> 

		<%= build_product_class_search_form(nil,'submit_product_classes_search','submit_product_classes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_product_classes_search
	if params['page']
		session[:product_classes_page] =params['page']
	else
		session[:product_classes_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @product_classes = dynamic_search(params[:product_class] ,'product_classes','ProductClass')
	else
		@product_classes = eval(session[:query])
	end
	if @product_classes.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_product_class_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_product_classes
		end

	else

		render_list_product_classes
	end
end

 
def delete_product_class
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:product_classes_page] = params['page']
		render_list_product_classes
		return
	end
	id = params[:id]
	if id && product_class = ProductClass.find(id)
		product_class.destroy
		session[:alert] = " Record deleted."
		render_list_product_classes
	end
end
 
def new_product_class
	return if authorise_for_web(program_name?,'create')== false
		render_new_product_class
end
 
def create_product_class
	 @product_class = ProductClass.new(params[:product_class])
	 if @product_class.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_product_class
	 end
end

def render_new_product_class
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new product_class'"%> 

		<%= build_product_class_form(@product_class,'create_product_class','create_product_class',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_product_class
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @product_class = ProductClass.find(id)
		render_edit_product_class

	 end
end


def render_edit_product_class
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit product_class'"%> 

		<%= build_product_class_form(@product_class,'update_product_class','update_product_class',true)%>

		}, :layout => 'content'
end
 
def update_product_class
	if params[:page]
		session[:product_classes_page] = params['page']
		render_list_product_classes
		return
	end

		@current_page = session[:product_classes_page]
	 id = params[:product_class][:id]
	 if id && @product_class = ProductClass.find(id)
		 if @product_class.update_attributes(params[:product_class])
			@product_classes = eval(session[:query])
			render_list_product_classes
	 else
			 render_edit_product_class

		 end
	 end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(product_classes)
#	-----------------------------------------------------------------------------------------------------------

end
