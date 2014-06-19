class Fg::LoadContainerController < ApplicationController

  def program_name?
    "load"
  end

  def bypass_generic_security?
    true
  end

  def list_load_containers
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:load_containers_page] = params['page']

      render_list_load_containers

      return
    else
      session[:load_containers_page] = nil
    end

    list_query = "@load_container_pages = Paginator.new self, LoadContainer.count, @@page_size,@current_page
	 @load_containers = LoadContainer.find(:all,
				 :limit => @load_container_pages.items_per_page,
				 :offset => @load_container_pages.current.offset)"
    session[:query] = list_query
    render_list_load_containers
  end


  def render_list_load_containers
    @pagination_server = "list_load_containers"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:load_containers_page]
    @current_page = params['page']||= session[:load_containers_page]
    @load_containers =  eval(session[:query]) if !@load_containers
    render :inline => %{
      <% grid            = build_load_container_grid(@load_containers,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all load_containers' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@load_container_pages) if @load_container_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_load_containers_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_load_container_search_form
  end

  def render_load_container_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  load_containers'"%> 

		<%= build_load_container_search_form(nil,'submit_load_containers_search','submit_load_containers_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_load_containers_search
    @load_containers = dynamic_search(params[:load_container], 'load_containers', 'LoadContainer')
    if @load_containers.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_load_container_search_form
    else
      render_list_load_containers
    end
  end


  def delete_load_container
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:load_containers_page] = params['page']
        render_list_load_containers
        return
      end
      id = params[:id]
      if id && load_container = LoadContainer.find(id)
        load_container.destroy
        session[:alert] = " Record deleted."
        render_list_load_containers
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_load_container
    return if authorise_for_web(program_name?, 'create')== false
    render_new_load_container
  end

  def create_load_container
    begin
      @load_container = LoadContainer.new(params[:load_container])
      if @load_container.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_load_container
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_load_container
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new load_container'"%> 

		<%= build_load_container_form(@load_container,'create_load_container','create_load_container',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_load_container
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @load_container = LoadContainer.find(id)
      render_edit_load_container

    end
  end


  def render_edit_load_container
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit load_container'"%> 

		<%= build_load_container_form(@load_container,'update_load_container','update_load_container',true)%>

		}, :layout => 'content'
  end

  def update_load_container
    begin

      id = params[:load_container][:id]
      if id && @load_container = LoadContainer.find(id)
        if @load_container.update_attributes(params[:load_container])
          @load_containers = eval(session[:query])
          flash[:notice] = 'record saved'
          render_list_load_containers
        else
          render_edit_load_container

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: stack_type_id
#	---------------------------------------------------------------------------------
  def load_container_stack_type_code_changed
    stack_type_code = get_selected_combo_value(params)
    session[:load_container_form][:stack_type_code_combo_selection] = stack_type_code
    @ids = LoadContainer.ids_for_stack_type_code(stack_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
		<%= select('load_container','id',@ids)%>

		}

  end


end
