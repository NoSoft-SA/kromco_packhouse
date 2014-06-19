class Fg::IwController < ApplicationController
  
  def program_name?
    "IW"
  end

  def bypass_generic_security?
    true
  end

  #=======================================================
  #  VEHICLES 
  #=======================================================
  def new_vehicle
    return if authorise_for_web(program_name?,'create') == false
    render_new_vehicle
  end

  def render_new_vehicle
    render :inline => %{
		<% @content_header_caption = "'create new vehicle'"%>

		<%= build_vehicle_form(@vehicle,'create_vehicle','create vehicle',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_vehicle
    begin
    	 @vehicle = Vehicle.new(params[:vehicle])
    	 if @vehicle.save
    		 redirect_to_index("'new vehicle record created successfully'","'create successful'")
    	 else
    		@is_create_retry = true
    		render_new_vehicle
    	 end
    rescue
       handle_error("vehicle record could not be created")
    end
  end

  def list_vehicles
    return if authorise_for_web(program_name?,'read') == false

    if params[:page]!= nil

      session[:vehicles_page] = params['page']

       render_list_vehicles

       return
    else
      session[:vehicles_page] = nil
    end

    list_query = "@vehicles_pages = Paginator.new self, Vehicle.count, @@page_size,@current_page
     @vehicles = Vehicle.find(:all,
           :limit => @vehicles_pages.items_per_page,
           :offset => @vehicles_pages.current.offset)"
    session[:query] = list_query
    render_list_vehicles
  end

  def render_list_vehicles
    @can_edit = authorise(program_name?,'edit',session[:user_id])
  	@can_delete = authorise(program_name?,'delete',session[:user_id])
  	@current_page = session[:vehicles_page] if session[:vehicles_page]
  	@current_page = params['page'] if params['page']
  	@vehicles =  eval(session[:query]) if !@vehicles
  	
  	render :inline => %{
      <% grid            = build_vehicles_grid(@vehicles,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all vehicles' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@vehicles_pages) if @vehicles_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_vehicle
    return if authorise_for_web(program_name?,'edit')==false
     id = params['id']
     if id && @vehicle = Vehicle.find(id)
        render_edit_vehicle
     end
  end

  def render_edit_vehicle
    render :inline => %{
		<% @content_header_caption = "'edit vehicle record'"%>

		<%= build_vehicle_form(@vehicle,'update_vehicle','update vehicle',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_vehicle
    begin
    if params[:page]
      session[:vehicles_page] = params['page']
      render_list_vehicles
      return
    end

      @current_page = session[:vehicles_page]
     id = params[:vehicle][:id]
     if id && @vehicle = Vehicle.find(id)
       if @vehicle.update_attributes(params[:vehicle])
          @vehicles = eval(session[:query])
          flash[:notice] = 'vehicle record updated!'
          render_list_vehicles
       else
           render_edit_vehicle
       end
     end
    rescue
       handle_error("vehicle record could not be updated")
    end
  end

  def delete_vehicle
    begin
    	return if authorise_for_web(program_name?,'delete')== false
    	if params[:page]
    		session[:vehicles_page] = params['page']
    		render_list_vehicles
    		return
    	end
    	id = params[:id]
    	if id && vehicle = Vehicle.find(id)
    		vehicle.destroy
    		session[:alert] = " Record deleted."
    		render_list_vehicles
    	end
    rescue
       handle_error("vehicle record could not be deleted")
    end
  end

end
