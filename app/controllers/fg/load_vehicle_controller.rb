class Fg::LoadVehicleController < ApplicationController

  def program_name?
    "load"
  end

  def bypass_generic_security?
    true
  end

  def list_load_vehicles
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:load_vehicles_page] = params['page']

      render_list_load_vehicles

      return
    else
      session[:load_vehicles_page] = nil
    end

    list_query = "@load_vehicle_pages = Paginator.new self, LoadVehicle.count, @@page_size,@current_page
	 @load_vehicles = LoadVehicle.find(:all,
				 :limit => @load_vehicle_pages.items_per_page,
				 :offset => @load_vehicle_pages.current.offset)"
    session[:query] = list_query
    render_list_load_vehicles
  end


  def render_list_load_vehicles
    @pagination_server = "list_load_vehicles"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:load_vehicles_page]
    @current_page = params['page']||= session[:load_vehicles_page]
    @load_vehicles =  eval(session[:query]) if !@load_vehicles
    render :inline => %{
      <% grid            = build_load_vehicle_grid(@load_vehicles,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all load_vehicles' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@load_vehicle_pages) if @load_vehicle_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_load_vehicles_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_load_vehicle_search_form
  end

  def render_load_vehicle_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  load_vehicles'"%> 

		<%= build_load_vehicle_search_form(nil,'submit_load_vehicles_search','submit_load_vehicles_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_load_vehicles_search
    @load_vehicles = dynamic_search(params[:load_vehicle], 'load_vehicles', 'LoadVehicle')
    if @load_vehicles.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_load_vehicle_search_form
    else
      render_list_load_vehicles
    end
  end


  def delete_load_vehicle
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:load_vehicles_page] = params['page']
        render_list_load_vehicles
        return
      end
      id = params[:id]
      if id && load_vehicle = LoadVehicle.find(id)
        load_vehicle.destroy
        session[:alert] = " Record deleted."
        render_list_load_vehicles
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_load_vehicle
    return if authorise_for_web(program_name?, 'create')== false
    render_new_load_vehicle
  end

  def create_load_vehicle
    begin
      @load_vehicle = LoadVehicle.new(params[:load_vehicle])
      if @load_vehicle.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_load_vehicle
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_load_vehicle
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new load_vehicle'"%> 

		<%= build_load_vehicle_form(@load_vehicle,'create_load_vehicle','create_load_vehicle',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_load_vehicle
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @load_vehicle = LoadVehicle.find(id)
      render_edit_load_vehicle

    end
  end


  def render_edit_load_vehicle
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit load_vehicle'"%> 

		<%= build_load_vehicle_form(@load_vehicle,'update_load_vehicle','update_load_vehicle',true)%>

		}, :layout => 'content'
  end

  def update_load_vehicle
    begin

      id = params[:load_vehicle][:id]
      if id && @load_vehicle = LoadVehicle.find(id)
        if @load_vehicle.update_attributes(params[:load_vehicle])
          @load_vehicles = eval(session[:query])
          flash[:notice] = 'record saved'
          render_list_load_vehicles
        else
          render_edit_load_vehicle

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end


end
