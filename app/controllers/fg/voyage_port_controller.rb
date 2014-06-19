class Fg::VoyagePortController < ApplicationController

  def program_name?
    "voyage"
  end

  def bypass_generic_security?
    true
  end

  def list_voyage_ports
    return if authorise_for_web(program_name?, 'read') == false


    if params[:page]!= nil

      session[:voyage_ports_page] = params['page']

      render_list_voyage_ports

      return
    else
      session[:voyage_ports_page] = nil
    end

    if params[:id]
      id = params[:id]
      list_query = "@voyage_port_pages = Paginator.new self, VoyagePort.count, @@page_size,@current_page
       @voyage_ports = VoyagePort.find(:all,
                  :conditions => \"voyage_ports.voyage_id = '#{id}'\",
                   :limit => @voyage_port_pages.items_per_page,
                   :offset => @voyage_port_pages.current.offset)"

    else
      list_query = "@voyage_port_pages = Paginator.new self, VoyagePort.count, @@page_size,@current_page
	 @voyage_ports = VoyagePort.find(:all,
				 :limit => @voyage_port_pages.items_per_page,
				 :offset => @voyage_port_pages.current.offset)"
    end

    session[:query] = list_query
    render_list_voyage_ports
  end


  def render_list_voyage_ports
    @pagination_server = "list_voyage_ports"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:voyage_ports_page]
    @current_page = params['page']||= session[:voyage_ports_page]
    @voyage_ports =  eval(session[:query]) if !@voyage_ports
    render :inline => %{
      <% grid            = build_voyage_port_grid(@voyage_ports,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all voyage_ports' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@voyage_port_pages) if @voyage_port_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_voyage_ports_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_voyage_port_search_form
  end

  def render_voyage_port_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  voyage_ports'"%> 

		<%= build_voyage_port_search_form(nil,'submit_voyage_ports_search','submit_voyage_ports_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def search_voyage_ports_hierarchy
    return if authorise_for_web(program_name?, 'read')== false

    @is_flat_search = false
    render_voyage_port_search_form(true)
  end

  def render_voyage_port_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  voyage_ports'"%> 

		<%= build_voyage_port_search_form(nil,'submit_voyage_ports_search','submit_voyage_ports_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def submit_voyage_ports_search
    @voyage_ports = dynamic_search(params[:voyage_port], 'voyage_ports', 'VoyagePort')
    if @voyage_ports.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_voyage_port_search_form
    else
      render_list_voyage_ports
    end
  end


  def delete_voyage_port
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:voyage_ports_page] = params['page']
        render_list_voyage_ports
        return
      end
      id = params[:id]
      if id && voyage_port = VoyagePort.find(id)
        voyage_port.destroy
        session[:alert] = " Record deleted."
        render_list_voyage_ports
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_voyage_port
    return if authorise_for_web(program_name?, 'create')== false
    render_new_voyage_port
  end

  def create_voyage_port
    begin
      @voyage_port = VoyagePort.new(params[:voyage_port])
      if @voyage_port.save
        js_inject = "<script>
                        window.opener.reloadFrame('child_form_iframe')
                        alert('Voyage Port Created');
                        window.close();
                  </script>"
        render_new_voyage_port(js_inject)
      else
        @is_create_retry = true
        render_new_voyage_port
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_voyage_port(update_main_window = "")
    @update_main_window = update_main_window
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new voyage_port'"%> 
        <%= @update_main_window %>
		<%= build_voyage_port_form(@voyage_port,'create_voyage_port','create_voyage_port',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_voyage_port
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @voyage_port = VoyagePort.find(id)
      render_edit_voyage_port

    end
  end


  def render_edit_voyage_port
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit voyage_port'"%> 

		<%= build_voyage_port_form(@voyage_port,'update_voyage_port','update_voyage_port',true)%>

		}, :layout => 'content'
  end

  def update_voyage_port
    begin

      id = params[:voyage_port][:id]
      if id && @voyage_port = VoyagePort.find(id)
        if @voyage_port.update_attributes(params[:voyage_port])
          @voyage_ports = eval(session[:query])
          js_inject = "<script>
                           window.opener.reloadFrame('child_form_iframe')
                           alert('Voyage Port Updated');
                           window.close();
                     </script>"
          render_new_voyage_port(js_inject)
#			flash[:notice] = 'record saved'
#			render_list_voyage_ports
        else
          render_edit_voyage_port

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end


#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(voyage_ports)
#	-----------------------------------------------------------------------------------------------------------

end
