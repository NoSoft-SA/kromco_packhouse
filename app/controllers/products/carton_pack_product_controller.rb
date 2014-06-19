class  Products::CartonPackProductController < ApplicationController
 
def program_name?
	"carton_pack_product"
end

def bypass_generic_security?
	true
end
def list_carton_pack_products
	return if authorise_for_web('carton_pack_product','read') == false 

    @can_edit = authorise_for_web('carton_pack_product','create')
    
 	if params[:page]!= nil 

 		session[:carton_pack_products_page] = params['page']

		 render_list_carton_pack_products

		 return 
	else
		session[:carton_pack_products_page] = nil
	end

	list_query = "@carton_pack_product_pages = Paginator.new self, CartonPackProduct.count, @@page_size,@current_page
	 @carton_pack_products = CartonPackProduct.find(:all,
				 :limit => @carton_pack_product_pages.items_per_page,
				 :order => 'carton_pack_product_code',
				 :offset => @carton_pack_product_pages.current.offset)"
	session[:query] = list_query
	render_list_carton_pack_products
end


def render_list_carton_pack_products
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:carton_pack_products_page] if session[:carton_pack_products_page]
	@current_page = params['page'] if params['page']
	@carton_pack_products =  eval(session[:query]) if !@carton_pack_products
	render :inline => %{
      <% grid            = build_carton_pack_product_grid(@carton_pack_products,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all carton_pack_products' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@carton_pack_product_pages) if @carton_pack_product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_carton_pack_products_flat
	return if authorise_for_web('carton_pack_product','read')== false
	@is_flat_search = true 
	render_carton_pack_product_search_form
end

def render_carton_pack_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  carton_pack_products'"%> 

		<%= build_carton_pack_product_search_form(nil,'submit_carton_pack_products_search','submit_carton_pack_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_carton_pack_products_hierarchy
	return if authorise_for_web('carton_pack_product','read')== false
 
	@is_flat_search = false 
	render_carton_pack_product_search_form(true)
end

def render_carton_pack_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  carton_pack_products'"%> 

		<%= build_carton_pack_product_search_form(nil,'submit_carton_pack_products_search','submit_carton_pack_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_carton_pack_products_search
	if params['page']
		session[:carton_pack_products_page] =params['page']
	else
		session[:carton_pack_products_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @carton_pack_products = dynamic_search(params[:carton_pack_product] ,'carton_pack_products','CartonPackProduct',true,nil,"carton_pack_product_code")
	else
		@carton_pack_products = eval(session[:query])
	end
	if @carton_pack_products.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_carton_pack_product_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_carton_pack_products
		end

	else

		render_list_carton_pack_products
	end
end

 
def delete_carton_pack_product
	return if authorise_for_web('carton_pack_product','delete')== false
	if params[:page]
		session[:carton_pack_products_page] = params['page']
		render_list_carton_pack_products
		return
	end
	id = params[:id]
	if id && carton_pack_product = CartonPackProduct.find(id)
		carton_pack_product.destroy
		session[:alert] = " Record deleted."
		render_list_carton_pack_products
	end
end
 
def new_carton_pack_product

	return if authorise_for_web('carton_pack_product','create')== false
		render_new_carton_pack_product
end
 
def create_carton_pack_product
   begin
	 @carton_pack_product = CartonPackProduct.new(params[:carton_pack_product])
	 if @carton_pack_product.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_carton_pack_product
	 end
   rescue
     handle_error("carton pack product could not be created")
   end
end

def render_new_carton_pack_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new carton_pack_product'"%> 

		<%= build_carton_pack_product_form(@carton_pack_product,'create_carton_pack_product','create_carton_pack_product',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_carton_pack_product
	return if authorise_for_web('carton_pack_product','edit')==false 
	 id = params[:id]
	 if id && @carton_pack_product = CartonPackProduct.find(id)
		render_edit_carton_pack_product

	 end
end

def view_paging_handler

  if params[:page]
	session[:carton_pack_products_page] = params['page']
  end
  render_list_carton_pack_products
end

def view_carton_pack_product
	return if authorise_for_web('carton_pack_product','edit')==false 
	 id = params[:id]
	 if id && @carton_pack_product = CartonPackProduct.find(id)
		render :inline => %{
		<% @content_header_caption = "'view carton_pack_product'"%> 

		<%= view_carton_pack_product(@carton_pack_product)%>

		}, :layout => 'content'

	 end
end

def render_edit_carton_pack_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit carton_pack_product'"%> 

		<%= build_carton_pack_product_form(@carton_pack_product,'update_carton_pack_product','update_carton_pack_product',true)%>

		}, :layout => 'content'
end
 
def update_carton_pack_product
	if params[:page]
		session[:carton_pack_products_page] = params['page']
		render_list_carton_pack_products
		return
	end

		@current_page = session[:carton_pack_products_page]
	 id = params[:carton_pack_product][:id]
	 if id && @carton_pack_product = CartonPackProduct.find(id)
		 if @carton_pack_product.update_attributes(params[:carton_pack_product])
			@carton_pack_products = eval(session[:query])
			render_list_carton_pack_products
	 else
			 render_edit_carton_pack_product

		 end
	 end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: carton_pack_type_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: basic_pack_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(carton_pack_products)
#	-----------------------------------------------------------------------------------------------------------
def carton_pack_product_type_code_search_combo_changed
	type_code = get_selected_combo_value(params)
	session[:carton_pack_product_search_form][:type_code_combo_selection] = type_code
	@basic_pack_codes = CartonPackProduct.find_by_sql("Select distinct basic_pack_code from carton_pack_products where type_code = '#{type_code}'").map{|g|[g.basic_pack_code]}
	@basic_pack_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('carton_pack_product','basic_pack_code',@basic_pack_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_carton_pack_product_basic_pack_code'/>
		<%= observe_field('carton_pack_product_basic_pack_code',:update => 'carton_pack_style_code_cell',:url => {:action => session[:carton_pack_product_search_form][:basic_pack_code_observer][:remote_method]},:loading => "show_element('img_carton_pack_product_basic_pack_code');",:complete => session[:carton_pack_product_search_form][:basic_pack_code_observer][:on_completed_js])%>
		}

end


def carton_pack_product_basic_pack_code_search_combo_changed
	basic_pack_code = get_selected_combo_value(params)
	session[:carton_pack_product_search_form][:basic_pack_code_combo_selection] = basic_pack_code
	type_code = 	session[:carton_pack_product_search_form][:type_code_combo_selection]
	@carton_pack_style_codes = CartonPackProduct.find_by_sql("Select distinct carton_pack_style_code from carton_pack_products where basic_pack_code = '#{basic_pack_code}' and type_code = '#{type_code}'").map{|g|[g.carton_pack_style_code]}
	@carton_pack_style_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('carton_pack_product','carton_pack_style_code',@carton_pack_style_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_carton_pack_product_carton_pack_style_code'/>
		<%= observe_field('carton_pack_product_carton_pack_style_code',:update => 'height_cell',:url => {:action => session[:carton_pack_product_search_form][:carton_pack_style_code_observer][:remote_method]},:loading => "show_element('img_carton_pack_product_carton_pack_style_code');",:complete => session[:carton_pack_product_search_form][:carton_pack_style_code_observer][:on_completed_js])%>
		}

end
 

def carton_pack_product_carton_pack_style_code_search_combo_changed
	carton_pack_style_code = get_selected_combo_value(params)
	session[:carton_pack_product_search_form][:carton_pack_style_code_combo_selection] = carton_pack_style_code
	basic_pack_code = 	session[:carton_pack_product_search_form][:basic_pack_code_combo_selection]
	type_code = 	session[:carton_pack_product_search_form][:type_code_combo_selection]
	@sizes = CartonPackProduct.find_by_sql("Select distinct height from carton_pack_products where carton_pack_style_code = '#{carton_pack_style_code}' and basic_pack_code = '#{basic_pack_code}' and type_code = '#{type_code}'").map{|g|[g.height]}
	@sizes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('carton_pack_product','height',@sizes)%>

		}

end



end
