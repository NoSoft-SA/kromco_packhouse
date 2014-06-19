class  Products::UnitPackProductController < ApplicationController
 
 


  def bypass_generic_security?
    true
  end


  def list_unit_pack_products
    return if authorise_for_web('unit_pack_product','read') == false
    @can_edit = authorise_for_web('unit_pack_product','create')

    if params[:page]!= nil

      session[:unit_pack_products_page] = params['page']


      render_list_unit_pack_products

      return
    else
      session[:unit_pack_products_page] = nil
    end

    list_query = "@unit_pack_product_pages = Paginator.new(self, UnitPackProduct.count, 20,@current_page)
	 @unit_pack_products = UnitPackProduct.find(:all,
				 :limit => @unit_pack_product_pages.items_per_page,
				 :order => 'unit_pack_product_code',
				 :offset => @unit_pack_product_pages.current.offset)"
    session[:query] = list_query
    render_list_unit_pack_products
  end


  def render_list_unit_pack_products
    @pagination_server = "render_list_unit_pack_products"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    if params['page']
     session[:unit_pack_products_page] = params['page']
    else
      params['page'] = session[:unit_pack_products_page]
    end
    
    @current_page = params['page']
    @unit_pack_products =  eval(session[:query])
  
    render :inline => %{
      <% grid            = build_unit_pack_product_grid(@unit_pack_products,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of unit packs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@unit_pack_product_pages) if @unit_pack_product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end
 
  def search_unit_pack_products_flat
    return if authorise_for_web('unit_pack_product','read')== false
    @is_flat_search = true
    render_unit_pack_product_search_form
  end

  def render_unit_pack_product_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    #	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  unit_pack_products'"%> 

		<%= build_unit_pack_product_search_form(nil,'submit_unit_pack_products_search','submit_unit_pack_products_search',@is_flat_search)%>

		}, :layout => 'content'
  end
 
  def search_unit_pack_products_hierarchy
    return if authorise_for_web('unit_pack_product','read')== false
 
    @is_flat_search = false
    render_unit_pack_product_search_form(true)
  end

  def render_unit_pack_product_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    #	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  unit_pack_products'"%> 

		<%= build_unit_pack_product_search_form(nil,'submit_unit_pack_products_search','submit_unit_pack_products_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_unit_pack_products_search

    @unit_pack_products = dynamic_search(params[:unit_pack_product] ,'unit_pack_products','UnitPackProduct',true, nil,'unit_pack_product_code')
	
    if @unit_pack_products.length == 0
		
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_unit_pack_product_search_form
		else
			
			render_list_unit_pack_products
		end

  end

 
  def delete_unit_pack_product
    return if authorise_for_web('unit_pack_product','delete')== false
    if params[:page]
      session[:unit_pack_products_page] = params['page']
      render_list_unit_pack_products
      return
    end
    id = params[:id]
    if id && unit_pack_product = UnitPackProduct.find(id)
      unit_pack_product.destroy
      session[:alert] = " Record deleted."
      render_list_unit_pack_products
    end
  end
 
  def new_unit_pack_product

    return if authorise_for_web('unit_pack_product','create')== false
		render_new_unit_pack_product
  end
 
  def create_unit_pack_product
    @unit_pack_product = UnitPackProduct.new(params[:unit_pack_product])
    if @unit_pack_product.save

      redirect_to_index("'new record created successfully'","'create successful'")
    else
      @is_create_retry = true
      render_new_unit_pack_product
    end
  end

  def render_new_unit_pack_product
    #	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new unit_pack_product'"%> 

		<%= build_unit_pack_product_form(@unit_pack_product,'create_unit_pack_product','create_unit_pack_product',false,@is_create_retry)%>

		}, :layout => 'content'
  end
 
  def edit_unit_pack_product
    return if authorise_for_web('unit_pack_product','edit')==false
    id = params[:id]
    if id && @unit_pack_product = UnitPackProduct.find(id)
      render_edit_unit_pack_product

    end
  end

  def view_paging_handler

    if params[:page]
      session[:unit_pack_products_page] = params['page']
    end
    render_list_unit_pack_products
  end


  def view_unit_pack_product
    id = params[:id]
    if id && @unit_pack_product = UnitPackProduct.find(id)
      render :inline => %{
		<% @content_header_caption = "'view unit_pack_product'"%> 

		<%= view_unit_pack_product(@unit_pack_product)%>

      }, :layout => 'content'

    end


  end

  def render_edit_unit_pack_product
    #	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit unit_pack_product'"%> 

		<%= build_unit_pack_product_form(@unit_pack_product,'update_unit_pack_product','update_unit_pack_product',true)%>

		}, :layout => 'content'
  end


  def update_unit_pack_product


		
    id = params[:unit_pack_product][:id]
    if id && @unit_pack_product = UnitPackProduct.find(id)
      @unit_pack_product.gross_mass = params[:unit_pack_product]['gross_mass'].to_f
      @unit_pack_product.product_description = params[:unit_pack_product]['product_description']
      @unit_pack_product.external_fruit_per_ru = params[:unit_pack_product]['external_fruit_per_ru']
      if @unit_pack_product.update
        @unit_pack_products = eval(session[:query])
        render_list_unit_pack_products
      else
        render_edit_unit_pack_product

      end
    end
  end
 
  #	-----------------------------------------------------------------------------------------------------------
  #	 search combo_changed event handlers for the unique index on this table(unit_pack_products)
  #	-----------------------------------------------------------------------------------------------------------
  def unit_pack_product_type_code_search_combo_changed
    type_code = get_selected_combo_value(params)
    session[:unit_pack_product_search_form][:type_code_combo_selection] = type_code
    @subtype_codes = UnitPackProduct.find_by_sql("Select distinct subtype_code from unit_pack_products where type_code = '#{type_code}'").map{|g|[g.subtype_code]}
    @subtype_codes.unshift("<empty>")

    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('unit_pack_product','subtype_code',@subtype_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_unit_pack_product_subtype_code'/>
		<%= observe_field('unit_pack_product_subtype_code',:update => 'gross_mass_cell',:url => {:action => session[:unit_pack_product_search_form][:subtype_code_observer][:remote_method]},:loading => "show_element('img_unit_pack_product_subtype_code');",:complete => session[:unit_pack_product_search_form][:subtype_code_observer][:on_completed_js])%>
		}

  end


  def unit_pack_product_subtype_code_search_combo_changed
    subtype_code = get_selected_combo_value(params)
    session[:unit_pack_product_search_form][:subtype_code_combo_selection] = subtype_code
    type_code = 	session[:unit_pack_product_search_form][:type_code_combo_selection]
    @gross_masses = UnitPackProduct.find_by_sql("Select distinct gross_mass from unit_pack_products where subtype_code = '#{subtype_code}' and type_code = '#{type_code}'").map{|g|[g.gross_mass]}
    @gross_masses.unshift("<empty>")

    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('unit_pack_product','gross_mass',@gross_masses)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_unit_pack_product_gross_mass'/>
		<%= observe_field('unit_pack_product_gross_mass',:update => 'fruit_per_ru_cell',:url => {:action => session[:unit_pack_product_search_form][:gross_mass_observer][:remote_method]},:loading => "show_element('img_unit_pack_product_gross_mass');",:complete => session[:unit_pack_product_search_form][:gross_mass_observer][:on_completed_js])%>
		}

  end


  def unit_pack_product_gross_mass_search_combo_changed
    gross_mass = get_selected_combo_value(params)
    gross_mass = -1 if gross_mass == ""
    session[:unit_pack_product_search_form][:gross_mass_combo_selection] = gross_mass
    subtype_code = 	session[:unit_pack_product_search_form][:subtype_code_combo_selection]
    type_code = 	session[:unit_pack_product_search_form][:type_code_combo_selection]
    @fruit_per_rus = UnitPackProduct.find_by_sql("Select distinct fruit_per_ru from unit_pack_products where gross_mass = '#{gross_mass}' and subtype_code = '#{subtype_code}' and type_code = '#{type_code}'").map{|g|[g.fruit_per_ru]}
    @fruit_per_rus.unshift("<empty>")

    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('unit_pack_product','fruit_per_ru',@fruit_per_rus)%>

		}

  end
end
