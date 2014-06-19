class Fg::LoadTypeController < ApplicationController

  def program_name?
    "load"
  end

  def bypass_generic_security?
    true
  end

  def list_load_types
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:load_types_page] = params['page']

      render_list_load_types

      return
    else
      session[:load_types_page] = nil
    end

    list_query = "@load_type_pages = Paginator.new self, LoadType.count, @@page_size,@current_page
	 @load_types = LoadType.find(:all,
				 :limit => @load_type_pages.items_per_page,
				 :offset => @load_type_pages.current.offset)"
    session[:query] = list_query
    render_list_load_types
  end


  def render_list_load_types
    @pagination_server = "list_load_types"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:load_types_page]
    @current_page = params['page']||= session[:load_types_page]
    @load_types =  eval(session[:query]) if !@load_types
    render :inline => %{
      <% grid            = build_load_type_grid(@load_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all load_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@load_type_pages) if @load_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_load_types_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_load_type_search_form
  end

  def render_load_type_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  load_types'"%> 

		<%= build_load_type_search_form(nil,'submit_load_types_search','submit_load_types_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_load_types_search
    @load_types = dynamic_search(params[:load_type], 'load_types', 'LoadType')
    if @load_types.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_load_type_search_form
    else
      render_list_load_types
    end
  end


  def delete_load_type
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:load_types_page] = params['page']
        render_list_load_types
        return
      end
      id = params[:id]
      if id && load_type = LoadType.find(id)
        load_type.destroy
        session[:alert] = " Record deleted."
        render_list_load_types
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_load_type
    return if authorise_for_web(program_name?, 'create')== false
    render_new_load_type
  end

  def create_load_type
    begin
      @load_type = LoadType.new(params[:load_type])
      if @load_type.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_load_type
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_load_type
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new load_type'"%> 

		<%= build_load_type_form(@load_type,'create_load_type','create_load_type',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_load_type
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @load_type = LoadType.find(id)
      render_edit_load_type

    end
  end


  def render_edit_load_type
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit load_type'"%> 

		<%= build_load_type_form(@load_type,'update_load_type','update_load_type',true)%>

		}, :layout => 'content'
  end

  def update_load_type
    begin

      id = params[:load_type][:id]
      if id && @load_type = LoadType.find(id)
        if @load_type.update_attributes(params[:load_type])
          @load_types = eval(session[:query])
          flash[:notice] = 'record saved'
          render_list_load_types
        else
          render_edit_load_type

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end


end
