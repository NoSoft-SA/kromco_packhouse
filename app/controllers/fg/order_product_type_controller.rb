class Fg::OrderProductTypeController < ApplicationController

  def program_name?
    "order"
  end

  def bypass_generic_security?
    true
  end

  def list_order_product_types
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:order_product_types_page] = params['page']

      render_list_order_product_types

      return
    else
      session[:order_product_types_page] = nil
    end

    list_query = "@order_product_type_pages = Paginator.new self, OrderProductType.count, @@page_size,@current_page
	 @order_product_types = OrderProductType.find(:all,
				 :limit => @order_product_type_pages.items_per_page,
				 :offset => @order_product_type_pages.current.offset)"
    session[:query] = list_query
    render_list_order_product_types
  end


  def render_list_order_product_types
    @pagination_server = "list_order_product_types"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:order_product_types_page]
    @current_page = params['page']||= session[:order_product_types_page]
    @order_product_types = eval(session[:query]) if !@order_product_types
    render :inline => %{
      <% grid            = build_order_product_type_grid(@order_product_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all order_product_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@order_product_type_pages) if @order_product_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_order_product_types_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_order_product_type_search_form
  end

  def render_order_product_type_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  order_product_types'"%> 

		<%= build_order_product_type_search_form(nil,'submit_order_product_types_search','submit_order_product_types_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_order_product_types_search
    @order_product_types = dynamic_search(params[:order_product_type], 'order_product_types', 'OrderProductType')
    if @order_product_types.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_order_product_type_search_form
    else
      render_list_order_product_types
    end
  end


  def delete_order_product_type
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:order_product_types_page] = params['page']
        render_list_order_product_types
        return
      end
      id = params[:id]
      if id && order_product_type = OrderProductType.find(id)
        order_product_type.destroy
        session[:alert] = " Record deleted."
        render_list_order_product_types
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_order_product_type
    return if authorise_for_web(program_name?, 'create')== false
    render_new_order_product_type
  end

  def create_order_product_type
    begin
      @order_product_type = OrderProductType.new(params[:order_product_type])
      if @order_product_type.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_order_product_type
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_order_product_type
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new order_product_type'"%> 

		<%= build_order_product_type_form(@order_product_type,'create_order_product_type','create_order_product_type',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_order_product_type
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @order_product_type = OrderProductType.find(id)
      render_edit_order_product_type

    end
  end


  def render_edit_order_product_type
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit order_product_type'"%> 

		<%= build_order_product_type_form(@order_product_type,'update_order_product_type','update_order_product_type',true)%>

		}, :layout => 'content'
  end

  def update_order_product_type
    begin

      id = params[:order_product_type][:id]
      if id && @order_product_type = OrderProductType.find(id)
        if @order_product_type.update_attributes(params[:order_product_type])
          @order_product_types = eval(session[:query])
          flash[:notice] = 'record saved'
          render_list_order_product_types
        else
          render_edit_order_product_type

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end


end
