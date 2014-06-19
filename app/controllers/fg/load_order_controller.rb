class Fg::LoadOrderController < ApplicationController

  def program_name?
    "load"
  end

  def bypass_generic_security?
    true
  end

  def list_load_orders
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:load_orders_page] = params['page']

      render_list_load_orders

      return
    else
      session[:load_orders_page] = nil
    end

    list_query = "@load_order_pages = Paginator.new self, LoadOrder.count, @@page_size,@current_page
	 @load_orders = LoadOrder.find(:all,
				 :limit => @load_order_pages.items_per_page,
				 :offset => @load_order_pages.current.offset)"
    session[:query] = list_query
    render_list_load_orders
  end


  def render_list_load_orders
    @pagination_server = "list_load_orders"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:load_orders_page]
    @current_page = params['page']||= session[:load_orders_page]
    @load_orders =  eval(session[:query]) if !@load_orders
    render :inline => %{
      <% grid            = build_load_order_grid(@load_orders,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all load_orders' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@load_order_pages) if @load_order_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_load_orders_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_load_order_search_form
  end

  def render_load_order_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  load_orders'"%> 

		<%= build_load_order_search_form(nil,'submit_load_orders_search','submit_load_orders_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_load_orders_search
    @load_orders = dynamic_search(params[:load_order], 'load_orders', 'LoadOrder')
    if @load_orders.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_load_order_search_form
    else
      render_list_load_orders
    end
  end


  def delete_load_order
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:load_orders_page] = params['page']
        render_list_load_orders
        return
      end
      id = params[:id]
      if id && load_order = LoadOrder.find(id)
        load_order.destroy
        session[:alert] = " Record deleted."
        render_list_load_orders
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_load_order
    return if authorise_for_web(program_name?, 'create')== false
    render_new_load_order
  end

  def create_load_order
    begin
      @load_order = LoadOrder.new(params[:load_order])
      if @load_order.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_load_order
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_load_order
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new load_order'"%> 

		<%= build_load_order_form(@load_order,'create_load_order','create_load_order',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_load_order
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @load_order = LoadOrder.find(id)
      render_edit_load_order

    end
  end


  def render_edit_load_order
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit load_order'"%> 

		<%= build_load_order_form(@load_order,'update_load_order','update_load_order',true)%>

		}, :layout => 'content'
  end

  def update_load_order
    begin

      id = params[:load_order][:id]
      if id && @load_order = LoadOrder.find(id)
        if @load_order.update_attributes(params[:load_order])
          @load_orders = eval(session[:query])
          flash[:notice] = 'record saved'
          render_list_load_orders
        else
          render_edit_load_order

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: order_id
#	---------------------------------------------------------------------------------
  def load_order_order_number_changed
    order_number = get_selected_combo_value(params)
    session[:load_order_form][:order_number_combo_selection] = order_number
    @customer_party_role_ids = LoadOrder.customer_party_role_ids_for_order_number(order_number)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
		<%= select('load_order','customer_party_role_id',@customer_party_role_ids)%>

		}

  end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: vehicle_job_id
#	---------------------------------------------------------------------------------
  def load_order_id_changed
    id = get_selected_combo_value(params)
    session[:load_order_form][:id_combo_selection] = id
    @vehicle_job_numbers = LoadOrder.vehicle_job_numbers_for_id(id)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
		<%= select('load_order','vehicle_job_number',@vehicle_job_numbers)%>

		}

  end


end
