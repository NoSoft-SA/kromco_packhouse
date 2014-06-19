class Fg::LoadVoyageController < ApplicationController

  def program_name?
    "load"
  end

  def bypass_generic_security?
    true
  end

  def list_load_voyages
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:load_voyages_page] = params['page']

      render_list_load_voyages

      return
    else
      session[:load_voyages_page] = nil
    end

    list_query = "@load_voyage_pages = Paginator.new self, LoadVoyage.count, @@page_size,@current_page
	 @load_voyages = LoadVoyage.find(:all,
				 :limit => @load_voyage_pages.items_per_page,
				 :offset => @load_voyage_pages.current.offset)"
    session[:query] = list_query
    render_list_load_voyages
  end


  def render_list_load_voyages
    @pagination_server = "list_load_voyages"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:load_voyages_page]
    @current_page = params['page']||= session[:load_voyages_page]
    @load_voyages =  eval(session[:query]) if !@load_voyages
    render :inline => %{
      <% grid            = build_load_voyage_grid(@load_voyages,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all load_voyages' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@load_voyage_pages) if @load_voyage_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_load_voyages_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_load_voyage_search_form
  end

  def render_load_voyage_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  load_voyages'"%> 

		<%= build_load_voyage_search_form(nil,'submit_load_voyages_search','submit_load_voyages_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_load_voyages_search
    @load_voyages = dynamic_search(params[:load_voyage], 'load_voyages', 'LoadVoyage')
    if @load_voyages.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_load_voyage_search_form
    else
      render_list_load_voyages
    end
  end


  def delete_load_voyage
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:load_voyages_page] = params['page']
        render_list_load_voyages
        return
      end
      id = params[:id]
      if id && load_voyage = LoadVoyage.find(id)
        load_voyage.destroy
        session[:alert] = " Record deleted."
        render_list_load_voyages
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_load_voyage
    return if authorise_for_web(program_name?, 'create')== false
    render_new_load_voyage
  end

  def create_load_voyage
    begin
      @load_voyage = LoadVoyage.new(params[:load_voyage])
      if @load_voyage.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_load_voyage
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_load_voyage
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new load_voyage'"%> 

		<%= build_load_voyage_form(@load_voyage,'create_load_voyage','create_load_voyage',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_load_voyage
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]

    if id && @load_voyage = LoadVoyage.find(id)


      puts "_________________________________________________________"
      puts "Load_voyage: "
      puts "load_id: " + session['load_id'].to_s
      puts "load_voyage_id: " + session['load_voyage_id'].to_s

      puts @load_voyage.to_xml
      puts "_________________________________________________________"


      render_edit_load_voyage
    else
      render_new_load_voyage
    end

  end


  def render_edit_load_voyage
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit load_voyage'"%> 

		<%= build_load_voyage_form(@load_voyage,'update_load_voyage','update_load_voyage',true)%>

		}, :layout => 'content'
  end

  def update_load_voyage

    @load_voyage = LoadVoyage.find_by_load_id(session['load_id'])

    if @load_voyage.update_attributes(params[:load_voyage])
      #@load_voyages = eval(session[:query])

      flash[:notice] = 'record saved'
      render :inline => "<script>window.close()</script>", :layout => 'content'
    else
      flash[:notice] = 'record not saved'
    end
  end


end
