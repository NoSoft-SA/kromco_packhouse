class  Products::PackMaterialProductController < ApplicationController
 
 #fix: paging fixed
 
def program_name?
	"pack_material_product"
end

def bypass_generic_security?
	true
end

#===============
#COMPOSITES CODE
#===============

def build_composite
  return if authorise_for_web(program_name?,'edit')== false 
	 id = params[:id]
	 if id && @product = Product.find(id)
	    session[:root_composite]= @product
		render :inline => %{
		<% @content_header_caption = "'build composite pack material product'"%> 

		<% @tree_script =  build_composite_tree(@product)%>

		}, :layout => 'tree'

	 end
	 
end

def add_product
  
  return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @product = Product.find(id)
	   session[:current_composite_pack_mat]= @product
	   @caption = "Add pack material product to composite product: " + @product.product_code
		render :inline => %{
		<% @hide_content_pane = false %>
        <% @is_menu_loaded_view = true %>
		<% @tree_node_content_header = @caption%> 

		<%= build_add_product_form()%>

		}, :layout => 'tree_node_content'

	 end


end


def change_quantity

   begin
   id = params[:id]
   @product = Product.find(id)
    product_code = session[:root_composite].product_code
	childproduct_code = @product.product_code
	if @composite =  session[:root_composite].composite_products.find(:first,:conditions => "product_code = '#{product_code}' and childproduct_code = '#{childproduct_code}'")
      @caption = "edit quantity of composite item: " + @product.product_code
      render :inline => %{
		<% @hide_content_pane = false %>
        <% @is_menu_loaded_view = true %>
		<% @tree_node_content_header = @caption%> 

		<%= build_edit_quantity_form(@composite,'update_quantity')%>

		}, :layout => 'tree_node_content'
		
    end
   
  rescue
   handle_error("quantity edit form rendering failed")
  end

end

 def update_quantity
  if @comp = CompositeProduct.find(params[:composite][:id])
    
    if params[:composite][:quantity].to_i > 0
     @comp.quantity = params[:composite][:quantity].to_i
     @comp.update
     flash[:notice]= "quantity updated"
    end
    
    @new_text = @comp.childproduct_code + ":" + @comp.quantity.to_s
      render :inline => %{
        
        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = false %>
        <% @tree_actions = render_edit_node_js(@new_text) %>
      
      
      },:layout => "tree_node_content"
  end
 
 end


def remove_product
  begin
   id = params[:id]
   @product = Product.find(id)
    product_code = session[:root_composite].product_code
	childproduct_code = @product.product_code
	if  session[:root_composite].composite_products.find(:first,:conditions => "product_code = '#{product_code}' and childproduct_code = '#{childproduct_code}'").destroy
      
     flash[:notice]= "pack material removed from composite"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>
     
     },:layout => "tree_node_content"
      
    end
   
  rescue
   handle_error("pack_material could not be removed from composite")
  end


end


def add_product_submit
    
    if params[:product][:product_code].index("select")||params[:product][:product_code]== ""
      redirect_to_index("You have not selected a product to add")
      return
    end
    
    if params[:product][:product_code]== session[:root_composite].product_code
      redirect_to_index("You cannot add a product to itself. That's just ridiculous")
      return
    end
    
    @product = Product.find_by_product_code(params[:product][:product_code])
	#determine the node_type: tricky part is to detrmine whether this node
    #is a direct child of the root node: this will be the case only if:
    #session[:current_composite_pack_mat]is same as session[:root_composite]
    
    @node_type = nil
    
    if session[:current_composite_pack_mat].id == session[:root_composite].id
      if @product.is_composite == true
        @node_type = "complex_root_child"
      else
        @node_type = "simple_root_child"
      end
    else
      if @product.is_composite == true
        @node_type = "complex_child"
      else
        @node_type = "simple_child"
      end
    
    end
    
    @comp_product = CompositeProduct.new
    @comp_product.quantity = params[:product][:quantity].to_i
    @comp_product.product_code = session[:current_composite_pack_mat].product_code
    @comp_product.childproduct_code = @product.product_code
	
	
	if session[:current_composite_pack_mat].composite_products.push(@comp_product)
      if @product.is_composite && @product.composite_products.length > 0
          @root_id = session[:root_composite].id.to_s
          render :inline => %{
        
        <script> window.parent.location.href = "/products/pack_material_product/build_composite/<%=@root_id%>"; </script>
        
       },:layout => "tree_node_content"
     else
        @node_name = @product.product_code + ":" + @comp_product.quantity.to_s
        @node_id = @product.id.to_s
        @tree_name = "composites"
        flash[:notice] = "pack material added to composite"
        render :inline => %{
        <% @is_menu_loaded_view = false %>
        <% @hide_content_pane = true %>
        <% tree_code = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>
        <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"
      end
    else
     redirect_to_index("error occurred")
    end
end


def list_products
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:products_page] = params['page']

		 render_list_products

		 return 
	else
		session[:products_page] = nil
	end

	if session[:composites_query] == nil
	 @freeze_flash = true
	 redirect_to_index(" You don't have any cached composites. Use the 'search' or 'find' menu actions to fetch composites. <br> The results will be cached for quick retrieval later on")
	else
	 session[:query]= session[:composites_query]
	 render_list_products("'List of cached schedules'")
	end
end


def render_list_products(caption = nil)
    @caption = "'list of all products'"
    @caption = caption if caption
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:products_page] if session[:products_page]
	@current_page = params['page'] if params['page']
	@products =  eval(session[:query]) if !@products
      render :inline => %{
      <% grid            = build_product_grid(@products,@can_edit,@can_delete) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@product_pages) if @product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_products_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_product_search_form
end

def render_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  products'"%> 

		<%= build_product_search_form(nil,'submit_products_search','submit_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_products_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_product_search_form(true)
end

def render_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  products'"%> 

		<%= build_product_search_form(nil,'submit_products_search','submit_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_products_search
	if params['page']
		session[:products_page] =params['page']
	else
		session[:products_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
	     #add some attributes: product_type must be 'PACK_MATERIAL' and 'is_composite' must be 'true'
		 params[:product][:is_composite]= 'true'
		 params[:product][:product_type_code]= "PACK_MATERIAL"
		 @products = dynamic_search(params[:product] ,'products','Product',true,nil,"product_code")
		  session[:composites_query]= session[:query]
	else
		@products = eval(session[:query])
	end
	if @products.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search]
			render_product_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_products
		end

	else

		render_list_products
	end
end

 
def delete_product
 return if authorise_for_web(program_name?,'delete')== false
   
	if params[:page]
		session[:products_page] = params['page']
		render_list_products
		return
	end
	id = params[:id]
	begin
	if id && product = Product.find(id)
		product.destroy
		session[:alert] = " Record deleted."
		render_list_products
	end
	rescue
	 handle_error("composite could not be deleted")
	end
end
 
def new_composite
	return if authorise_for_web(program_name?,'create')== false
		render_new_product
end
 
def create_product
	 @product = Product.new(params[:product])
	 @product.product_type_code = "PACK_MATERIAL"
	 @product.product_type = ProductType.find_by_product_type_code("PACK_MATERIAL")
	 @product.is_composite = true
	 if @product.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_product
	 end
end

def render_new_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new product'"%> 

		<%= build_product_form(@product,'create_product','create_product',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_product
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @product = Product.find(id)
		render_edit_product

	 end
end


def render_edit_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit product'"%> 

		<%= build_product_form(@product,'update_product','update_product',true)%>

		}, :layout => 'content'
end
 
def update_product
	if params[:page]
		session[:products_page] = params['page']
		render_list_products
		return
	end

		@current_page = session[:products_page]
	 id = params[:product][:id]
	 if id && @product = Product.find(id)
		 if @product.update_attributes(params[:product])
			@products = eval(session[:query])
			render_list_products
	 else
			 render_edit_product

		 end
	 end
 end
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(products)
#	-----------------------------------------------------------------------------------------------------------
def product_product_subtype_code_search_combo_changed
	product_subtype_code = get_selected_combo_value(params)
	session[:product_search_form][:product_subtype_code_combo_selection] = product_subtype_code
	@tag1s = Product.find_by_sql("Select distinct tag1 from products where product_subtype_code = '#{product_subtype_code}' and product_type_code = 'PACK_MATERIAL' and is_composite = 'true'").map{|g|[g.tag1]}
	@tag1s.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('product','tag1',@tag1s)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_product_tag1'/>
		<%= observe_field('product_tag1',:update => 'tag2_cell',:url => {:action => session[:product_search_form][:tag1_observer][:remote_method]},:loading => "show_element('img_product_tag1');",:complete => session[:product_search_form][:tag1_observer][:on_completed_js])%>
		}

end


def product_tag1_search_combo_changed
	tag1 = get_selected_combo_value(params)
	session[:product_search_form][:tag1_combo_selection] = tag1
	product_subtype_code = 	session[:product_search_form][:product_subtype_code_combo_selection]
	@tag2s = Product.find_by_sql("Select distinct tag2 from products where tag1 = '#{tag1}' and product_subtype_code = '#{product_subtype_code}' and product_type_code = 'PACK_MATERIAL' and is_composite = 'true'").map{|g|[g.tag2]}
	@tag2s.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('product','tag2',@tag2s)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_product_tag2'/>
		<%= observe_field('product_tag2',:update => 'tag3_cell',:url => {:action => session[:product_search_form][:tag2_observer][:remote_method]},:loading => "show_element('img_product_tag2');",:complete => session[:product_search_form][:tag2_observer][:on_completed_js])%>
		}

end


def product_tag2_search_combo_changed
	tag2 = get_selected_combo_value(params)
	session[:product_search_form][:tag2_combo_selection] = tag2
	tag1 = 	session[:product_search_form][:tag1_combo_selection]
	product_subtype_code = 	session[:product_search_form][:product_subtype_code_combo_selection]
	@tag3s = Product.find_by_sql("Select distinct tag3 from products where tag2 = '#{tag2}' and tag1 = '#{tag1}' and product_subtype_code = '#{product_subtype_code}' and product_type_code = 'PACK_MATERIAL' and is_composite = 'true' ").map{|g|[g.tag3]}
	@tag3s.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('product','tag3',@tag3s)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_product_tag3'/>
		<%= observe_field('product_tag3',:update => 'product_code_cell',:url => {:action => session[:product_search_form][:tag3_observer][:remote_method]},:loading => "show_element('img_product_tag3');",:complete => session[:product_search_form][:tag3_observer][:on_completed_js])%>
		}

end


def product_tag3_search_combo_changed
	tag3 = get_selected_combo_value(params)
	session[:product_search_form][:tag3_combo_selection] = tag3
	tag2 = 	session[:product_search_form][:tag2_combo_selection]
	tag1 = 	session[:product_search_form][:tag1_combo_selection]
	product_subtype_code = 	session[:product_search_form][:product_subtype_code_combo_selection]
	@product_codes = Product.find_by_sql("Select distinct product_code from products where tag3 = '#{tag3}' and tag2 = '#{tag2}' and tag1 = '#{tag1}' and product_subtype_code = '#{product_subtype_code}' and product_type_code = 'PACK_MATERIAL' and is_composite = 'true'").map{|g|[g.product_code]}
	@product_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('product','product_code',@product_codes)%>

		}

end

def product_product_subtype_code_combo_changed
	product_subtype_code = get_selected_combo_value(params)
	
	@product_codes = Product.find_by_sql("Select distinct product_code from products where product_subtype_code = '#{product_subtype_code}' and product_type_code = 'PACK_MATERIAL'").map{|g|[g.product_code]}
	@product_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('product','product_code',@product_codes)%>
		}

end


#===============
#PRIMITIVES CODE
#===============

def configure_pack_material
 return if authorise_for_web('pack_material_product','create')== false
	begin
		render :inline => %{
		<% @content_header_caption = "'select pack material type and subtype'"%> 

		<%= build_set_type_form('configure_pack_material_step2')%>

		}, :layout => 'content'
	 rescue
	  handle_error("Pack material form could not be rendered")
	 end


end

def configure_pack_material_step2
  @type_code = params[:pack_material_type][:pack_material_type_code]
  @sub_type_code = params[:pack_material_type][:pack_material_sub_type_code]
  
  
  if (@sub_type_code.index("select")!= nil||@sub_type_code == nil)
   @freeze_flash = true
   redirect_to_index("You must select a type code and a sub type code")
  else
    pm_type_id  = PackMaterialType.find_by_pack_material_type_code(@type_code).id
    pm_subtype = PackMaterialSubType.find_by_pack_material_type_id_and_pack_material_subtype_code(pm_type_id,@sub_type_code)
    session[:config_subtype]= pm_subtype
    @pm_config = PackMaterialProductConfig.find_by_pack_material_sub_type_id(pm_subtype.id)
    @pm_config = PackMaterialProductConfig.new if !@pm_config
    session[:pm_config]= @pm_config
    render_configure_pack_material_product
  end
end
 
 def save_pack_material_config
  begin
   session[:pm_config].update_attributes_state(params[:pm_config])
   session[:pm_config].pack_material_sub_type = session[:config_subtype]
  
   if session[:pm_config].save
     redirect_to_index("Configuration record created")
   else
     redirect_to_index("Configuration record NOT created")
   end
  rescue
   handle_error("Configuration record could not be saved")
  end
 
 end



 def render_configure_pack_material_product
   
   render :inline => %{
		<% @content_header_caption = "'configure fields to use for pack material'"%> 

		<%= build_configure_pack_material_form(@pm_config,@type_code,@sub_type_code)%>

		}, :layout => 'content'
   
 
 end
 

def list_pack_material_products
	return if authorise_for_web('pack_material_product','read') == false 

 	if params[:page]!= nil 

 		session[:pack_material_products_page] = params['page']

		 render_list_pack_material_products

		 return 
	else
		session[:pack_material_products_page] = nil
	end

	list_query = "@pack_material_product_pages = Paginator.new self, PackMaterialProduct.count, @@page_size,@current_page
	 @pack_material_products = PackMaterialProduct.find(:all,
				 :limit => @pack_material_product_pages.items_per_page,
				 :offset => @pack_material_product_pages.current.offset,
				 :order => 'pack_material_product_code')"
	session[:query] = list_query
	render_list_pack_material_products
end


def render_list_pack_material_products
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:pack_material_products_page] if session[:pack_material_products_page]
	@current_page = params['page'] if params['page']
	@pack_material_products =  eval(session[:query]) if !@pack_material_products
	render :inline => %{
      <% grid            = build_pack_material_product_grid(@pack_material_products,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all pack_material_products' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pack_material_product_pages) if @pack_material_product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_pack_material_products_flat
	return if authorise_for_web('pack_material_product','read')== false
	@is_flat_search = true 
	render_pack_material_product_search_form
end

def render_pack_material_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pack_material_products'"%> 

		<%= build_pack_material_product_search_form(nil,'submit_pack_material_products_search','submit_pack_material_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_pack_material_products_hierarchy
	return if authorise_for_web('pack_material_product','read')== false
 
	@is_flat_search = false 
	render_pack_material_product_search_form(true)
end

def render_pack_material_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pack_material_products'"%> 

		<%= build_pack_material_product_search_form(nil,'submit_pack_material_products_search','submit_pack_material_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_pack_material_products_search
	if params['page']
		session[:pack_material_products_page] =params['page']
	else
		session[:pack_material_products_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @pack_material_products = dynamic_search(params[:pack_material_product] ,'pack_material_products','PackMaterialProduct',true,nil,'pack_material_product_code')
	    
	else
		@pack_material_products = eval(session[:query])
	end
	if @pack_material_products.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_pack_material_product_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_pack_material_products
		end

	else

		render_list_pack_material_products
	end
end

 
def delete_pack_material_product
  return if authorise_for_web('pack_material_product','delete')== false
  begin
	if params[:page]
		session[:pack_material_products_page] = params['page']
		render_list_pack_material_products
		return
	end
	id = params[:id]
	if id && pack_material_product = PackMaterialProduct.find(id)
		pack_material_product.destroy
		session[:alert] = " Record deleted."
		render_list_pack_material_products
	end
   rescue
    handle_error("pack material could not be deleted")
   end
end
 
def new_pack_material_product
	return if authorise_for_web('pack_material_product','create')== false
	begin
		render :inline => %{
		<% @content_header_caption = "'select pack material type'"%> 

		<%= build_set_type_form()%>

		}, :layout => 'content'
	 rescue
	  handle_error("Pack material form could not be rendered")
	 end
end

 def submit_create_pack_material_step1
  
  type_code = params[:pack_material_type][:pack_material_type_code]
  sub_type_code = params[:pack_material_type][:pack_material_sub_type_code]
  session[:new_selected_type_code]= type_code
  session[:new_selected_sub_type_code]= sub_type_code
  
  if (sub_type_code.index("select")!= nil||sub_type_code == nil)
   @freeze_flash = true
   redirect_to_index("You must select a type code and a sub type code")
  else
   render_new_pack_material_product
  end
 end
 
 
def create_pack_material_product_step2
  begin
	 @pack_material_product = PackMaterialProduct.new(params[:pack_material_product])
	 @pack_material_product.pack_material_type_code = session[:new_selected_type_code]
     @pack_material_product.pack_material_sub_type_code = session[:new_selected_sub_type_code]
	 
	 if @pack_material_product.save
         session[:new_selected_type_code]= nil
         session[:new_selected_sub_type_code] = nil
		 redirect_to_index("'new record created successfully'","'create successful'")
	 else
		@is_create_retry = true
		render_new_pack_material_product
	 end
  rescue
    handle_error("pack material could not be created")
  end
end

def render_new_pack_material_product
#	 render (inline) the edit template
  begin
	render :inline => %{
		<% @content_header_caption = "'create new pack_material_product'"%> 

		<%= build_pack_material_product_form(@pack_material_product,'create_pack_material_product_step2','create_pack_material_product',false,@is_create_retry)%>

		}, :layout => 'content'
  rescue
    handle_error("pack material form could not be rendered")
  end
end
 
def edit_pack_material_product
	return if authorise_for_web('pack_material_product','edit')==false 
	 id = params[:id]
	 if id && @pack_material_product = PackMaterialProduct.find(id)
		render_edit_pack_material_product

	 end
end


def render_edit_pack_material_product
#	 render (inline) the edit template
  begin
	render :inline => %{
		<% @content_header_caption = "'edit pack_material_product'"%> 

		<%= build_pack_material_product_form(@pack_material_product,'update_pack_material_product','update_pack_material_product',true)%>

		}, :layout => 'content'
 rescue
  handle_error("pack material edit form could not be rendered")
 end
end
 
def update_pack_material_product
  begin
	if params[:page]
		session[:pack_material_products_page] = params['page']
		render_list_pack_material_products
		return
	end

		@current_page = session[:pack_material_products_page]
	 id = params[:pack_material_product][:id]
	 if id && @pack_material_product = PackMaterialProduct.find(id)
		 if @pack_material_product.update_attributes(params[:pack_material_product])
			@pack_material_products = eval(session[:query])
			flash[:notice] = "pack material updated"
			render_list_pack_material_products
	    else
			 render_edit_pack_material_product

		 end
	 end
	rescue
	 handle_error("pack material could not be updated")
	end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: marketing_variety_id
#	---------------------------------------------------------------------------------
def pack_material_product_commodity_group_code_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:pack_material_product_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = PackMaterialProduct.commodity_codes_for_commodity_group_code(commodity_group_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('pack_material_product','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_pack_material_product_commodity_code'/>
		<%puts observe_field('pack_material_product_commodity_code',:update => 'marketing_variety_code_cell',:url => {:action => session[:pack_material_product_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_pack_material_product_commodity_code');",:complete => session[:pack_material_product_form][:commodity_code_observer][:on_completed_js])%>
		<%= observe_field('pack_material_product_commodity_code',:update => 'marketing_variety_code_cell',:url => {:action => session[:pack_material_product_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_pack_material_product_commodity_code');",:complete => session[:pack_material_product_form][:commodity_code_observer][:on_completed_js])%>
		}

end

def pack_material_type_code_changed

  	type_code = get_selected_combo_value(params)
    query = "SELECT 
            public.pack_material_sub_types.pack_material_subtype_code
            FROM
            public.pack_material_sub_types
            INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
            WHERE
           (public.pack_material_types.pack_material_type_code = '#{type_code}')"
           
	@subtypes =PackMaterialSubType.find_by_sql(query).map{|t|[t.pack_material_subtype_code]}
	
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('pack_material_type','pack_material_sub_type_code',@subtypes)%>

		}

end


def pack_material_product_commodity_code_changed
	commodity_code = get_selected_combo_value(params)
	session[:pack_material_product_form][:commodity_code_combo_selection] = commodity_code
	commodity_group_code = 	session[:pack_material_product_form][:commodity_group_code_combo_selection]
	@marketing_variety_codes = PackMaterialProduct.marketing_variety_codes_for_commodity_code_and_commodity_group_code(commodity_code,commodity_group_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('pack_material_product','marketing_variety_code',@marketing_variety_codes)%>

		}

end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: product_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(pack_material_products)
#	-----------------------------------------------------------------------------------------------------------
def pack_material_product_pack_material_type_code_search_combo_changed
	pack_material_type_code = get_selected_combo_value(params)
	session[:pack_material_product_search_form][:pack_material_type_code_combo_selection] = pack_material_type_code
	@pack_material_product_codes = PackMaterialProduct.find_by_sql("Select distinct pack_material_product_code from pack_material_products where pack_material_type_code = '#{pack_material_type_code}'").map{|g|[g.pack_material_product_code]}
	@pack_material_product_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('pack_material_product','pack_material_product_code',@pack_material_product_codes)%>

		}

end



end
