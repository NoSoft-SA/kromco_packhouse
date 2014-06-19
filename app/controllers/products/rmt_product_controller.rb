class  Products::RmtProductController < ApplicationController
 
 #fix: paging fixed
 
def program_name?
	"rmt_product"
end

def bypass_generic_security?
	true
end
def list_rmt_products
	return if authorise_for_web('rmt_product','read') == false 

    if params[:page]!= nil 

 		session[:rmt_products_page] = params['page']
		 render_list_rmt_products

		 return 
	else
		session[:rmt_products_page] = nil
	end

	
	list_query = "@rmt_product_pages = Paginator.new self, RmtProduct.count, @@page_size,@current_page
	 @rmt_products = RmtProduct.find(:all,
			 :limit => @rmt_product_pages.items_per_page,
			 :order => 'rmt_product_code',
			 :offset => @rmt_product_pages.current.offset,
			 :include => 'ripe_point')"
	session[:query] = list_query
	render_list_rmt_products
end

def view_paging_handler

  if params[:page]
	session[:rmt_products_page] = params['page']
  end
  render_list_rmt_products
end


def view_rmt_product

  id = params[:id]
  @rmt_product = RmtProduct.find(id)
  render :inline => %{
		<% @content_header_caption = "'view  rmt product'"%> 

		<%= build_rmt_product_view(@rmt_product)%>

		}, :layout => 'content'

end

def render_list_rmt_products
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	
	@current_page = session[:rmt_products_page] if session[:rmt_products_page]
	
	@current_page = params['page'] if params['page']
	
	@rmt_products =  eval(session[:query]) if !@rmt_products
	
	render :inline => %{
      <% grid            = build_rmt_product_grid(@rmt_products,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all rmt_products' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@rmt_product_pages) if @rmt_product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_rmt_products_flat
	return if authorise_for_web('rmt_product','read')== false
	@is_flat_search = true 
	render_rmt_product_search_form
end

def render_rmt_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rmt_products'"%> 

		<%= build_rmt_product_search_form(nil,'submit_rmt_products_search','submit_rmt_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_rmt_products_hierarchy
	return if authorise_for_web('rmt_product','read')== false
 
	@is_flat_search = false 
	render_rmt_product_search_form(true)
end

def render_rmt_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rmt_products'"%> 

		<%= build_rmt_product_search_form(nil,'submit_rmt_products_search','submit_rmt_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_rmt_products_search

	if params['page']
		session[:rmt_products_page] =params['page']
	else
		session[:rmt_products_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @rmt_products = dynamic_search(params[:rmt_product] ,'rmt_products','RmtProduct',true, 'ripe_point','rmt_product_code')
	else
		@rmt_products = eval(session[:query])
	end
	
	
	if @rmt_products.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_rmt_product_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_rmt_products
		end
	else
		session[:rmt_products] = @rmt_products
		@rmt_products = session[:rmt_products]
		render_list_rmt_products
	end
end

 
def delete_rmt_product
	return if authorise_for_web('rmt_product','delete')== false
	id = params[:id]
	if id && rmt_product = RmtProduct.find(id)
		rmt_product.destroy
		session[:alert] = " Record deleted."
#		 update in-memory recordset
		@rmt_products = session[:rmt_products]
		 delete_record(@rmt_products,id)
		session[:rmt_products] = @rmt_products
		render_list_rmt_products
	end
end
  
 def new_rmt_product_step1
    return if authorise_for_web('rmt_product','create') == false 
  	render :inline => %{
		<% @content_header_caption = "'create new rmt_product: select product type'"%> 

		<%= build_rmt_product_type_select_form('new_rmt_product_step2','next')%>

		}, :layout => 'content'
 
 end
 
def new_rmt_product_step2
    session[:rmt_product_type]= params[:rmt_product][:rmt_product_type]
    
	return if authorise_for_web('rmt_product','create')== false
		render_new_rmt_product
end
 
def create_rmt_product
   begin
	 @rmt_product = RmtProduct.new(params[:rmt_product])
	 @rmt_product.rmt_product_type_code = session[:rmt_product_type]
	 RAILS_DEFAULT_LOGGER.info ("@rmt_product.rmt_product_type_code: " + @rmt_product.rmt_product_type_code )   	 
	 if @rmt_product.save
	#update in-memory list- if it exists
		if session[:rmt_products]
			 session[:rmt_products].push @rmt_product
		end
		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_rmt_product
	 end
   rescue
    handle_error("rmt product could not be created")
   end
end

def render_new_rmt_product
#	 render (inline) the edit template
    @is_orchard_run = session[:rmt_product_type]
	RAILS_DEFAULT_LOGGER.info ("@is_orchard_run: " + @is_orchard_run )         
	render :inline => %{
		<% @content_header_caption = "'create new " + session[:rmt_product_type] + " rmt_product'"%> 

		<%= build_rmt_product_form(@rmt_product,'create_rmt_product','create_rmt_product',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_rmt_product
	return if authorise_for_web('rmt_product','edit')==false 
	 id = params[:id]
	 if id && @rmt_product = RmtProduct.find(id)
	    session[:rmt_product_type] = @rmt_product.rmt_product_type_code
		render_edit_rmt_product

	 end
end


def render_edit_rmt_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit " + @rmt_product.rmt_product_type_code + " rmt_product'"%> 

		<%= build_rmt_product_form(@rmt_product,'update_rmt_product','update_rmt_product',true)%>

		}, :layout => 'content'
end
 
def update_rmt_product
	 id = params[:rmt_product][:id]
	 if id && @rmt_product = RmtProduct.find(id)
		 if @rmt_product.update_attributes(params[:rmt_product])
#		update the in-memory recordset- to save db call
			update_record(session[:rmt_products],@rmt_product.attributes,id)
			@rmt_products = session[:rmt_products]
			render_list_rmt_products
		else
			 render_edit_rmt_product

		 end
	 end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: variety_id
#	---------------------------------------------------------------------------------
def rmt_product_commodity_group_code_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:rmt_product_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = RmtProduct.commodity_codes_for_commodity_group_code(commodity_group_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_commodity_code'/>
		<%= observe_field('rmt_product_commodity_code',:update => 'variety_code_cell',:url => {:action => session[:rmt_product_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_commodity_code');",:complete => session[:rmt_product_form][:commodity_code_observer][:on_completed_js])%>
		}

end


def rmt_product_commodity_code_changed
	commodity_code = get_selected_combo_value(params)
	session[:rmt_product_form][:commodity_code_combo_selection] = commodity_code
	commodity_group_code = 	session[:rmt_product_form][:commodity_group_code_combo_selection]
	@variety_codes = nil
	if session[:rmt_product_type]== "orchard_run"||session[:rmt_product_type]== "presort"
	 @variety_codes = Variety.find_by_sql("Select distinct rmt_variety_code as variety_code from varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.variety_code]}
	else
	 @variety_codes = Variety.find_by_sql("Select distinct marketing_variety_code as variety_code from varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.variety_code]}
	end
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','variety_code',@variety_codes)%>

		}

end

 def rmt_product_ripe_point_changed
     ripe_point_code = get_selected_combo_value(params)
	
	@description = ""
	ripe_point = RipePoint.find_by_ripe_point_code(ripe_point_code)
	@description = ripe_point.ripe_point_description if ripe_point
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
	<%= @description %>

	}
 
 
 end
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(rmt_products)
#	-----------------------------------------------------------------------------------------------------------
def rmt_product_commodity_group_code_search_combo_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = RmtProduct.find_by_sql("Select distinct commodity_code from rmt_products where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}
	@commodity_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_commodity_code'/>
		<%= observe_field('rmt_product_commodity_code',:update => 'variety_code_cell',:url => {:action => session[:rmt_product_search_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_commodity_code');",:complete => session[:rmt_product_search_form][:commodity_code_observer][:on_completed_js])%>
		}

end


def rmt_product_commodity_code_search_combo_changed
	commodity_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:commodity_code_combo_selection] = commodity_code
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@variety_codes = nil
	
	@variety_codes = RmtProduct.find_by_sql("Select distinct variety_code from rmt_products where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.variety_code]}
	
	
	@variety_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','variety_code',@variety_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_variety_code'/>
		<%= observe_field('rmt_product_variety_code',:update => 'size_code_cell',:url => {:action => session[:rmt_product_search_form][:variety_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_variety_code');",:complete => session[:rmt_product_search_form][:variety_code_observer][:on_completed_js])%>
		}

end


def rmt_product_variety_code_search_combo_changed
	variety_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:variety_code_combo_selection] = variety_code
	commodity_code = 	session[:rmt_product_search_form][:commodity_code_combo_selection]
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@size_codes = RmtProduct.find_by_sql("Select distinct size_code from rmt_products where variety_code = '#{variety_code}' and commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.size_code]}
	@size_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','size_code',@size_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_size_code'/>
		<%= observe_field('rmt_product_size_code',:update => 'product_class_code_cell',:url => {:action => session[:rmt_product_search_form][:size_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_size_code');",:complete => session[:rmt_product_search_form][:size_code_observer][:on_completed_js])%>
		}

end


def rmt_product_size_code_search_combo_changed
	size_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:size_code_combo_selection] = size_code
	variety_code = 	session[:rmt_product_search_form][:variety_code_combo_selection]
	commodity_code = 	session[:rmt_product_search_form][:commodity_code_combo_selection]
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@product_class_codes = RmtProduct.find_by_sql("Select distinct product_class_code from rmt_products where size_code = '#{size_code}' and variety_code = '#{variety_code}' and commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.product_class_code]}
	@product_class_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','product_class_code',@product_class_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_product_class_code'/>
		<%= observe_field('rmt_product_product_class_code',:update => 'ripe_point_code_cell',:url => {:action => session[:rmt_product_search_form][:product_class_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_product_class_code');",:complete => session[:rmt_product_search_form][:product_class_code_observer][:on_completed_js])%>
		}

end


def rmt_product_product_class_code_search_combo_changed
	product_class_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:product_class_code_combo_selection] = product_class_code
	size_code = 	session[:rmt_product_search_form][:size_code_combo_selection]
	variety_code = 	session[:rmt_product_search_form][:variety_code_combo_selection]
	commodity_code = 	session[:rmt_product_search_form][:commodity_code_combo_selection]
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@ripe_point_codes = RmtProduct.find_by_sql("Select distinct ripe_point_code from rmt_products where product_class_code = '#{product_class_code}' and size_code = '#{size_code}' and variety_code = '#{variety_code}' and commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.ripe_point_code]}
	@ripe_point_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','ripe_point_code',@ripe_point_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_ripe_point_code'/>
		<%= observe_field('rmt_product_ripe_point_code',:update => 'treatment_code_cell',:url => {:action => session[:rmt_product_search_form][:ripe_point_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_ripe_point_code');",:complete => session[:rmt_product_search_form][:ripe_point_code_observer][:on_completed_js])%>
		}

end


def rmt_product_ripe_point_code_search_combo_changed
	ripe_point_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:ripe_point_code_combo_selection] = ripe_point_code
	product_class_code = 	session[:rmt_product_search_form][:product_class_code_combo_selection]
	size_code = 	session[:rmt_product_search_form][:size_code_combo_selection]
	variety_code = 	session[:rmt_product_search_form][:variety_code_combo_selection]
	commodity_code = 	session[:rmt_product_search_form][:commodity_code_combo_selection]
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@treatment_codes = RmtProduct.find_by_sql("Select distinct treatment_code from rmt_products where ripe_point_code = '#{ripe_point_code}' and product_class_code = '#{product_class_code}' and size_code = '#{size_code}' and variety_code = '#{variety_code}' and commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.treatment_code]}
	@treatment_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','treatment_code',@treatment_codes)%>

		}

end



end
