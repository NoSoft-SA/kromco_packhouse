class  Products::PalletFormatProductController < ApplicationController
 
 #fix: paging fixed
 
def program_name?
	"pallet_format_product"
end

def bypass_generic_security?
	true
end
def list_pallet_format_products
	return if authorise_for_web('pallet_format_product','read') == false 

 	if params[:page]!= nil 

 		session[:pallet_format_products_page] = params['page']

		 render_list_pallet_format_products

		 return 
	else
		session[:pallet_format_products_page] = nil
	end

	list_query = "@pallet_format_product_pages = Paginator.new self, PalletFormatProduct.count, @@page_size,@current_page
	 @pallet_format_products = PalletFormatProduct.find(:all,
				 :limit => @pallet_format_product_pages.items_per_page,
				 :order => 'pallet_format_product_code',
				 :offset => @pallet_format_product_pages.current.offset)"
	session[:query] = list_query
	render_list_pallet_format_products
end


def render_list_pallet_format_products
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:pallet_format_products_page] if session[:pallet_format_products_page]
	@current_page = params['page'] if params['page']
	@pallet_format_products =  eval(session[:query]) if !@pallet_format_products
	render :inline => %{
      <% grid            = build_pallet_format_product_grid(@pallet_format_products,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all pallet_format_products' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pallet_format_product_pages) if @pallet_format_product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_pallet_format_products_flat
	return if authorise_for_web('pallet_format_product','read')== false
	@is_flat_search = true 
	render_pallet_format_product_search_form
end

def render_pallet_format_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pallet_format_products'"%> 

		<%= build_pallet_format_product_search_form(nil,'submit_pallet_format_products_search','submit_pallet_format_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_pallet_format_products_hierarchy
	return if authorise_for_web('pallet_format_product','read')== false
 
	@is_flat_search = false 
	render_pallet_format_product_search_form(true)
end

def render_pallet_format_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pallet_format_products'"%> 

		<%= build_pallet_format_product_search_form(nil,'submit_pallet_format_products_search','submit_pallet_format_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_pallet_format_products_search
	if params['page']
		session[:pallet_format_products_page] =params['page']
	else
		session[:pallet_format_products_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @pallet_format_products = dynamic_search(params[:pallet_format_product] ,'pallet_format_products','PalletFormatProduct',true,nil,'pallet_format_product_code')
	else
		@pallet_format_products = eval(session[:query])
	end
	if @pallet_format_products.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_pallet_format_product_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_pallet_format_products
		end

	else

		render_list_pallet_format_products
	end
end

 
def delete_pallet_format_product
	return if authorise_for_web('pallet_format_product','delete')== false
	if params[:page]
		session[:pallet_format_products_page] = params['page']
		render_list_pallet_format_products
		return
	end
	id = params[:id]
	if id && pallet_format_product = PalletFormatProduct.find(id)
		pallet_format_product.destroy
		session[:alert] = " Record deleted."
		render_list_pallet_format_products
	end
end
 
def new_pallet_format_product
	return if authorise_for_web('pallet_format_product','create')== false
		render_new_pallet_format_product
end
 
def create_pallet_format_product
	 @pallet_format_product = PalletFormatProduct.new(params[:pallet_format_product])
	 if @pallet_format_product.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_pallet_format_product
	 end
end

def render_new_pallet_format_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new pallet_format_product'"%> 

		<%= build_pallet_format_product_form(@pallet_format_product,'create_pallet_format_product','create_pallet_format_product',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_pallet_format_product
	return if authorise_for_web('pallet_format_product','edit')==false 
	 id = params[:id]
	 if id && @pallet_format_product = PalletFormatProduct.find(id)
		render_edit_pallet_format_product

	 end
end

def view_paging_handler

  if params[:page]
	session[:pallet_format_products_page] = params['page']
  end
  render_list_pallet_format_products
end


def view_pallet_format_product
	return if authorise_for_web('pallet_format_product','view')==false 
	 id = params[:id]
	 if id && @pallet_format_product = PalletFormatProduct.find(id)
		render :inline => %{
		<% @content_header_caption = "'view pallet_format_product'"%> 

		<%= view_pallet_format_product(@pallet_format_product)%>

		}, :layout => 'content'

	 end
end

def render_edit_pallet_format_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit pallet_format_product'"%> 

		<%= build_pallet_format_product_form(@pallet_format_product,'update_pallet_format_product','update_pallet_format_product',true)%>

		}, :layout => 'content'
end
 
def update_pallet_format_product
	if params[:page]
		session[:pallet_format_products_page] = params['page']
		render_list_pallet_format_products
		return
	end

		@current_page = session[:pallet_format_products_page]
	 id = params[:pallet_format_product][:id]
	 if id && @pallet_format_product = PalletFormatProduct.find(id)
		 if @pallet_format_product.update_attributes(params[:pallet_format_product])
			@pallet_format_products = eval(session[:query])
			render_list_pallet_format_products
	 else
			 render_edit_pallet_format_product

		 end
	 end
 end
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(pallet_format_products)
#	-----------------------------------------------------------------------------------------------------------
def pallet_format_product_market_code_search_combo_changed
	market_code = get_selected_combo_value(params)
	session[:pallet_format_product_search_form][:market_code_combo_selection] = market_code
	@stack_type_codes = PalletFormatProduct.find_by_sql("Select distinct stack_type_code from pallet_format_products where market_code = '#{market_code}'").map{|g|[g.stack_type_code]}
	@stack_type_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('pallet_format_product','stack_type_code',@stack_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_pallet_format_product_stack_type_code'/>
		<%= observe_field('pallet_format_product_stack_type_code',:update => 'pallet_base_code_cell',:url => {:action => session[:pallet_format_product_search_form][:stack_type_code_observer][:remote_method]},:loading => "show_element('img_pallet_format_product_stack_type_code');",:complete => session[:pallet_format_product_search_form][:stack_type_code_observer][:on_completed_js])%>
		}

end


def pallet_format_product_stack_type_code_search_combo_changed
	stack_type_code = get_selected_combo_value(params)
	stack_type_code = -1 if stack_type_code == ""
	session[:pallet_format_product_search_form][:stack_type_code_combo_selection] = stack_type_code
	market_code = 	session[:pallet_format_product_search_form][:market_code_combo_selection]
	@pallet_base_codes = PalletFormatProduct.find_by_sql("Select distinct pallet_base_code from pallet_format_products where stack_type_code = '#{stack_type_code}' and market_code = '#{market_code}'").map{|g|[g.pallet_base_code]}
	@pallet_base_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('pallet_format_product','pallet_base_code',@pallet_base_codes)%>

		}

end



end
