class  Products::HandlingProductController < ApplicationController
 
 #fix: paging fixed
 
def program_name?
	"handling_product"
end

def bypass_generic_security?
	true
end
def list_handling_products
  t.r
	return if authorise_for_web('handling_product','read') == false 

 	if params[:page]!= nil 

 		session[:handling_products_page] = params['page']

		 render_list_handling_products

		 return 
	else
		session[:handling_products_page] = nil
	end

	list_query = "@handling_product_pages = Paginator.new self, HandlingProduct.count, @@page_size,@current_page
	 @handling_products = HandlingProduct.find(:all,
				 :limit => @handling_product_pages.items_per_page,
				 :order => 'handling_product_code',
				 :offset => @handling_product_pages.current.offset)"
	session[:query] = list_query
	render_list_handling_products
end


def render_list_handling_products
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:handling_products_page] if session[:handling_products_page]
	@current_page = params['page'] if params['page']
	@handling_products =  eval(session[:query]) if !@handling_products
	render :inline => %{
      <% grid            = build_handling_product_grid(@handling_products,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all handling_products' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@handling_product_pages) if @handling_product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_handling_products_flat
	return if authorise_for_web('handling_product','read')== false
	@is_flat_search = true 
	render_handling_product_search_form
end

def render_handling_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  handling_products'"%> 

		<%= build_handling_product_search_form(nil,'submit_handling_products_search','submit_handling_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_handling_products_hierarchy
	return if authorise_for_web('handling_product','read')== false
 
	@is_flat_search = false 
	render_handling_product_search_form(true)
end

def render_handling_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  handling_products'"%> 

		<%= build_handling_product_search_form(nil,'submit_handling_products_search','submit_handling_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_handling_products_search
	if params['page']
		session[:handling_products_page] =params['page']
	else
		session[:handling_products_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @handling_products = dynamic_search(params[:handling_product] ,'handling_products','HandlingProduct',true,nil,'handling_product_code')
	else
		@handling_products = eval(session[:query])
	end
	if @handling_products.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_handling_product_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_handling_products
		end

	else

		render_list_handling_products
	end
end

 
def delete_handling_product
	return if authorise_for_web('handling_product','delete')== false
	if params[:page]
		session[:handling_products_page] = params['page']
		render_list_handling_products
		return
	end
	id = params[:id]
	if id && handling_product = HandlingProduct.find(id)
		handling_product.destroy
		session[:alert] = " Record deleted."
		render_list_handling_products
	end
end
 
def new_handling_product
	return if authorise_for_web('handling_product','create')== false
		render_new_handling_product
end
 
def create_handling_product
  begin
	 @handling_product = HandlingProduct.new(params[:handling_product])
	 if @handling_product.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_handling_product
	 end
   rescue
     handle_error("handling product could not be created")
   end
end

def render_new_handling_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new handling_product'"%> 

		<%= build_handling_product_form(@handling_product,'create_handling_product','create_handling_product',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_handling_product
	return if authorise_for_web('handling_product','edit')==false 
	 id = params[:id]
	 if id && @handling_product = HandlingProduct.find(id)
		render_edit_handling_product

	 end
end


def render_edit_handling_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit handling_product'"%> 

		<%= build_handling_product_form(@handling_product,'update_handling_product','update_handling_product',true)%>

		}, :layout => 'content'
end
 
def update_handling_product
	if params[:page]
		session[:handling_products_page] = params['page']
		render_list_handling_products
		return
	end

		@current_page = session[:handling_products_page]
	 id = params[:handling_product][:id]
	 if id && @handling_product = HandlingProduct.find(id)
		 if @handling_product.update_attributes(params[:handling_product])
			@handling_products = eval(session[:query])
			render_list_handling_products
	 else
			 render_edit_handling_product

		 end
	 end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: handling_product_type_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(handling_products)
#	-----------------------------------------------------------------------------------------------------------

end
