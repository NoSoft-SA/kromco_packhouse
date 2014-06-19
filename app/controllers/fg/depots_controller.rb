class Fg::DepotsController < ApplicationController

  def program_name?
    "depot_receipts"
  end

  def bypass_generic_security?
    true
  end

  def new_depot
    return if authorise_for_web(program_name?, 'create') == false
    render_new_depot
  end

  def render_new_depot
    render :inline => %{
		<% @content_header_caption = "'create new depot'"%>

		<%= build_depots_form(@depot,'create_depot','create depot',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_depot
    begin
      @depot = Depot.new(params[:depot])
      if @depot.save
        redirect_to_index("'depot record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_depot
      end
    rescue
      handle_error("depot record could not be created")
    end
  end

  def list_depots
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:depots_page] = params['page']

      render_list_depots

      return
    else
      session[:depots_page] = nil
    end

    list_query = "@depots_pages = Paginator.new self, Depot.count, @@page_size,@current_page
     @depots = Depot.find(:all,
           :limit => @depots_pages.items_per_page,
           :offset => @depots_pages.current.offset)"
    session[:query] = list_query
    render_list_depots
  end

  def render_list_depots
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:depots_page] if session[:depots_page]
    @current_page = params['page'] if params['page']
    @depots =  eval(session[:query]) if !@depots

    render :inline => %{
      <% grid            = build_depots_grid(@depots,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all depots' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@depots_pages) if @depots_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_depot
    return if authorise_for_web(program_name?, 'edit')==false
    id = params['id']
    if id && @depot = Depot.find(id)
      render_edit_depot
    end
  end

  def render_edit_depot
    render :inline => %{
		<% @content_header_caption = "'edit depot record'"%>

		<%= build_depots_form(@depot,'update_depot','update depot',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_depot
    begin
      if params[:page]
        session[:depots_page] = params['page']
        render_list_depots
        return
      end

      @current_page = session[:depots_page]
      id = params[:depot][:id]
      if id && @depot = Depot.find(id)
        if @depot.update_attributes(params[:depot])
          @depotss = eval(session[:query])
          flash[:notice] = 'depot record updated!'
          render_list_depots
        else
          render_edit_depot
        end
      end
    rescue
      handle_error("depot record could not be updated")
    end
  end

  def delete_depot
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:depots_page] = params['page']
        render_list_depots
        return
      end
      id = params[:id]
      if id && depot = Depot.find(id)
        depot.destroy
        session[:alert] = " Record deleted."
        render_list_depots
      end
    rescue
      handle_error("depot record could not be deleted")
    end
  end

  def find_depots
    return if authorise_for_web(program_name?, 'read')== false

    @is_flat_search = false
    render_find_depots_form
  end

  def render_find_depots_form
    session[:is_flat_search] = @is_flat_search
    render :inline => %{
		<% @content_header_caption = "'find depots'"%>

		<%= build_depots_search_form(nil,'submit_depots_search','find depots',@is_flat_search)%>

		}, :layout => 'content'
  end

  def submit_depots_search
    if params['page']
      session[:depots_page] =params['page']
    else
      session[:depots_page] = nil
    end
    @current_page = params['page']
    if params[:page]== nil
      session[:depot] = Hash.new
      if params[:depot][:location_code].to_s != ""
        location = Location.find_by_location_code(params[:depot][:location_code])
        if location
          session[:depot]["location_id"] = location.id
        end
      end
      if params[:depot][:party_name].to_s != "" || params[:depot][:party_name].to_s.upcase.index("SELECT A VALUE ") == nil
        parties_role = PartiesRole.find_by_party_name(params[:depot][:party_name])
        if parties_role
          session[:depot]["parties_role_id"] = parties_role.id
        end
      end
      session[:depot]["depot_code"] = params[:depot][:depot_code]

      @depots = dynamic_search(session[:depot], 'depots', 'Depot')
    else
      @depots = eval(session[:query])
    end
    if @depots.length == 0
      if params[:page] == nil
        flash[:notice] = 'no records were found for the query'
        @is_flat_search = session[:is_flat_search].to_s
        render_find_depots_form
      else
        flash[:notice] = 'There are no more records'
        render_list_depots
      end

    else
      render_list_depots
    end
  end


  def depots_location_code_search_combo_changed
    location_code = get_selected_combo_value(params)
    session[:depots_search_form][:location_code_combo_selection] = location_code
    @party_names = PartiesRole.find_by_sql("SELECT DISTINCT p.party_name from parties_roles p, locations l, depots d WHERE l.location_code='#{location_code}' AND l.id=d.location_id AND p.id=d.parties_role_id").map { |g| [g.party_name] }
    @party_names.unshift("<empty>")
    render :inline=>%{
        <%=select('depot','party_name',@party_names) %>
        <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_depot_party_name'/>
        <%= observe_field('depot_party_name', :update=>'depot_code_cell', :url => {:action=>session[:depots_search_form][:party_name_observer][:remote_method]}, :loading=>"show_element('img_depot_party_name');", :complete=>session[:depots_search_form][:party_name_observer][:on_completed_js])%>
    }
  end

  def depot_party_name_search_combo_changed
    party_name = get_selected_combo_value(params)
    location_code = session[:depots_search_form][:location_code_combo_selection]
    @depot_codes = Depot.find_by_sql("SELECT DISTINCT d.depot_code FROM depots d, locations l, parties_roles p WHERE(d.location_id=l.id AND d.parties_role_id=p.id AND p.party_name='#{party_name}' AND l.location_code='#{location_code}')").map { |g| [g.depot_code] }
    @depot_codes.unshift("<empty>")
    render :inline=>%{
        <%=select('depot','depot_code',@depot_codes) %>
    }
  end

end
