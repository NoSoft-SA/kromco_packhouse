class  RmtProcessing::PresortStagingRunChildController < ApplicationController

  def program_name?
    "presort_staging_run"
  end

  def bypass_generic_security?
    true
  end

  def staged_child_runs
    set_active_doc("presort_staging_run",params[:id])
    conditions="presort_staging_run_children.presort_staging_run_id=#{params[:id]} and presort_staging_run_children.status='STAGED' "
    get_children(conditions)
    @edit_mode=false
    session[:parent]=nil
    render_list_presort_staging_run_children
  end

  def parent_staged_child_runs
    set_active_doc("presort_staging_run",params[:id])
    conditions="presort_staging_run_children.presort_staging_run_id=#{params[:id]} and presort_staging_run_children.status='STAGED' "
    get_children(conditions)
    @edit_mode=false
    session[:parent]=true
    render_list_presort_staging_run_children
  end

  def editing_child_runs
    set_active_doc("presort_staging_run",params[:id])
    conditions="presort_staging_run_children.presort_staging_run_id=#{params[:id]} and presort_staging_run_children.status='EDITING' "
    get_children(conditions)
    @edit_mode=false
    session[:parent]=nil
    render_list_presort_staging_run_children
  end

  def parent_editing_child_runs
    set_active_doc("presort_staging_run",params[:id])
    conditions="presort_staging_run_children.presort_staging_run_id=#{params[:id]} and presort_staging_run_children.status='EDITING' "
    get_children(conditions)
    @edit_mode=false
    session[:parent]=true
    render_list_presort_staging_run_children
  end


  def active_child_runs
    set_active_doc("presort_staging_run",params[:id])
    conditions="presort_staging_run_children.presort_staging_run_id=#{params[:id]} and presort_staging_run_children.status='ACTIVE' "
    get_children(conditions)
    @edit_mode=false
    session[:parent]=nil
    render_list_presort_staging_run_children
  end

  def parent_active_child_runs
    set_active_doc("presort_staging_run",params[:id])
    conditions="presort_staging_run_children.presort_staging_run_id=#{params[:id]} and presort_staging_run_children.status='ACTIVE' "
    get_children(conditions)
    @edit_mode=false
    session[:parent]=true
    render_list_presort_staging_run_children
  end

  def bins_available_locations
    presort_staging_run_child=PresortStagingRunChild.find_by_sql("select farms.farm_code,presort_staging_run_children.*
                             from presort_staging_run_children inner join farms on presort_staging_run_children.farm_id=farms.id where presort_staging_run_children.id=#{params[:id]}")[0]
    presort_staging_run=PresortStagingRun.find(session[:active_doc]['presort_staging_run'])
    locations_query=PresortStagingRunChild.get_available_locations(presort_staging_run,presort_staging_run_child.farm_id)
    @locations=locations_query[0]
    @locations.each do |location|
      bin_age =Location.bin_age(location)
      location['bin_age']=bin_age
      location['id']=presort_staging_run_child.id
    end
    @locations = @locations.sort_by {|p| p.bin_age }
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{locations_query[1]}\")"
    @caption="'available locations  for child (#{presort_staging_run_child.presort_staging_run_child_code}) for FARM:#{presort_staging_run_child.farm_code}'"
    render_locations_grid
  end

  def location_farm_bins
    location_farm_code=params[:id].split("@")
    presort_staging_run=PresortStagingRun.find(session[:active_doc]['presort_staging_run'])
    presort_staging_run_child=PresortStagingRunChild.find_by_sql("select farms.farm_code,presort_staging_run_children.*
                             from presort_staging_run_children inner join farms on presort_staging_run_children.farm_id=farms.id where presort_staging_run_children.id=#{location_farm_code[2]}")[0]
    bins_query=PresortStagingRunChild.get_bins_per_location_farm(location_farm_code[0],location_farm_code[1],presort_staging_run,presort_staging_run_child.farm_id)
    @bins=bins_query[0]
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{bins_query[1]}\")"
    @caption="'bins available for LOCATION: #{location_farm_code[0]} and  FARM: #{location_farm_code[1]}'"
    render_bins_grid
  end

  def show_bins_staged
    presort_staging_run_child=PresortStagingRunChild.find_by_sql("select farms.farm_code,presort_staging_run_children.*
                             from presort_staging_run_children inner join farms on presort_staging_run_children.farm_id=farms.id where presort_staging_run_children.id=#{params[:id]}")[0]
    presort_staging_run=PresortStagingRun.find(session[:active_doc]['presort_staging_run'])
    staged_bins=PresortStagingRunChild.bins_staged(presort_staging_run_child.id)
    @bins=staged_bins[0]
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{staged_bins[1]}\")"
    @caption="'staged bins for child ( #{presort_staging_run_child.presort_staging_run_child_code}) for FARM: #{presort_staging_run_child.farm_code}'"
    render_bins_grid
  end

  def bins_available
    presort_staging_run_child=PresortStagingRunChild.find_by_sql("select farms.farm_code,presort_staging_run_children.*
                             from presort_staging_run_children inner join farms on presort_staging_run_children.farm_id=farms.id where presort_staging_run_children.id=#{params[:id]}")[0]
    presort_staging_run=PresortStagingRun.find(session[:active_doc]['presort_staging_run'])
    bins_query=PresortStagingRunChild.get_bins_available(presort_staging_run,presort_staging_run_child.farm_id)
    @bins=bins_query[0]
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{bins_query[1]}\")"
    @caption="' available locations for child ( #{presort_staging_run_child.presort_staging_run_child_code}) for FARM: #{presort_staging_run_child.farm_code}'"
    render_bins_grid
  end

  def render_bins_grid
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:presort_staging_runs_page]
    @current_page = params['page']||= session[:presort_staging_runs_page]
    render :inline => %{
  <% grid = build_bins_grid(@bins,@can_edit,@can_delete)%>
  <% grid.caption = @caption%>
  <% @header_content = grid.build_grid_data %>
  <% @pagination = pagination_links(@presort_staging_run_pages) if @presort_staging_run_pages != nil %>
  <% grid.group_fields     = ['location_code'] %>
  <% grid.groupable_fields = ['farm_code', 'location_code'] %>
  <% grid.grouped          = true %>
  <% grid.height           = @grid_height %>
  <%= grid.render_html %>
  <%= grid.render_grid %>
  },:layout => 'content'
  end

  def render_locations_grid
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:presort_staging_runs_page]
    @current_page = params['page']||= session[:presort_staging_runs_page]
    render :inline => %{
  <% grid = build_locations_grid(@locations,@can_edit,@can_delete)%>
  <% grid.caption = @caption%>
  <% @header_content = grid.build_grid_data %>
  <% @pagination = pagination_links(@presort_staging_run_pages) if @presort_staging_run_pages != nil %>
  <% grid.height           = @grid_height %>
  <%= grid.render_html %>
  <%= grid.render_grid %>
  },:layout => 'content'
    #<% grid.group_fields     = ['farm_code'] %>
    #<% grid.groupable_fields = ['farm_code', 'location_code'] %>
    #<% grid.grouped          = true %>
  end

  def edit_child_status
    return if authorise_for_web(program_name?,'edit') == false
    @presort_staging_run_child = PresortStagingRunChild.find(params[:id])
    session[:child_status]=   @presort_staging_run_child.status
    set_active_doc("presort_staging_run_child",@presort_staging_run_child.id)
    render :inline => %{
		<% @content_header_caption = "'new child run'"%>

		<%= build_edit_child_status_form(@presort_staging_run_child,'edit_child_status_submit','set status',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def check_for_active_child
    active_child=nil
    active_child=PresortStagingRunChild.find_by_status("ACTIVE")
    return active_child
  end

  def edit_child_status_submit
    id = session[:active_doc]['presort_staging_run_child']
    presort_staging_run =  PresortStagingRun.find(session[:active_doc]['presort_staging_run'])
    @presort_staging_run_child = PresortStagingRunChild.find(id)
    if  session[:child_status]!= params[:presort_staging_run_child][:status]
      if params[:presort_staging_run_child][:status]=="ACTIVE"
        active_child=check_for_active_child
        if active_child
          params[:id] = @presort_staging_run_child.id
          flash[:error] = 'status cannot be changed,another child already active'
          edit_child_status and return
        end
      end
    end
    if id && @presort_staging_run_child
      if params[:presort_staging_run_child][:status] !=  session[:child_status]
        child ={:list => [@presort_staging_run_child.id],
                :child_new_status_code => params[:presort_staging_run_child][:status],
                :child_status_type => "presort_staging_run_child",
                :child_ar_class_name => "PresortStagingRunChild"}
        StatusMan.set_status(presort_staging_run.status,"presort_staging_run",presort_staging_run,session[:user_id].user_name,nil,child,true)
        flash[:notice]="status changed"
        render :inline => %{<script>
             window.opener.frames[1].frames[0].location.reload(true);
             window.close();
          </script>} and return
      else
        render_edit_presort_staging_run_child
      end
    end
  rescue
    handle_error('record could not be saved')
  end

  def list_main_grid_run_children
    return if authorise_for_web(program_name?,'read') == false
    set_active_doc("presort_staging_run",params[:id])
    conditions="presort_staging_run_children.presort_staging_run_id=#{params[:id]} "
    get_children(conditions)
    @grid_cmd=false
    render_list_presort_staging_run_children
  end

  def list_presort_staging_run_children
    return if !authorise_for_web(program_name?, 'read')
    set_active_doc("presort_staging_run",params[:id])
    if params[:page]!= nil

      session[:presort_staging_run_children_page] = params['page']

      render_list_presort_staging_run_children

      return
    else
      session[:presort_staging_run_children_page] = nil
    end
    conditions="presort_staging_run_children.presort_staging_run_id=#{session[:active_doc]['presort_staging_run']}"
    get_children(conditions)
    @grid_cmd=true
    session[:parent]=nil
    render_list_presort_staging_run_children
  end

  def get_children(conditions)
    list_query = "select presort_staging_run_children.*,farms.farm_code from presort_staging_run_children
                inner join farms on presort_staging_run_children.farm_id=farms.id
                where #{conditions}"
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{list_query}\")"
  end


  def render_list_presort_staging_run_children
    @pagination_server = "child staging runs"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:presort_staging_run_children_page]
    @current_page = params['page']||= session[:presort_staging_run_children_page]
    @presort_staging_run_children =  eval(session[:query]) if !@presort_staging_run_children
    render :inline => %{
		<% grid = build_presort_staging_run_child_grid(@presort_staging_run_children,@can_edit,@can_delete,@grid_cmd)%>
		<% grid.caption = 'child staging runs'%>
    <%grid.height='200'%>
		<% @header_content = grid.build_grid_data %>

		<% @pagination = pagination_links(@presort_staging_run_child_pages) if @presort_staging_run_child_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
  end

  def search_presort_staging_run_children_flat
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true
    render_presort_staging_run_child_search_form
  end

  def render_presort_staging_run_child_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  presort_staging_run_children'"%>

		<%= build_presort_staging_run_child_search_form(nil,'submit_presort_staging_run_children_search','submit_presort_staging_run_children_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def delete_presort_staging_run_child
    return if authorise_for_web(program_name?,'delete')== false
    if params[:page]
      session[:presort_staging_run_children_page] = params['page']
      render_list_presort_staging_run_children
      return
    end
    id = params[:id]
    @run_id=session[:active_doc]['presort_staging_run']
    if id && presort_staging_run_child = PresortStagingRunChild.find(id)
      presort_staging_run_child.destroy
      render :inline => %{
              <script>
               alert("deleted");
              //window.opener.frames[0].frames[1].location.reload(true);
              window.opener.frames[1].frames[0].location.href = '/rmt_processing/presort_staging_run_child/list_presort_staging_run_children/<%=@run_id.to_s%>';
              window.close();
              </script>
              }, :layout => 'content'
    end
  rescue
    handle_error('record could not be deleted')
  end

  def new_presort_staging_run_child
    return if authorise_for_web(program_name?,'create')== false
    render_new_presort_staging_run_child
  end

  def render_new_presort_staging_run_child
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'new child run'"%>

		<%= build_presort_staging_run_child_form(@presort_staging_run_child,'create_presort_staging_run_child','create_child',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_presort_staging_run_child
    presort_staging_run =  PresortStagingRun.find(session[:active_doc]['presort_staging_run'])
    @presort_staging_run_child = PresortStagingRunChild.new(params[:presort_staging_run_child])
    @presort_staging_run_child.presort_staging_run_id=session[:active_doc]['presort_staging_run']
    if @presort_staging_run_child.save
      PresortStagingRun.set_child_status('EDITING',@presort_staging_run_child,presort_staging_run,session[:user_id].user_name)
      flash[:notice]="new record created successfully"
      render :inline => %{<script>
             window.close();
             window.opener.frames[0].location.reload(true);
          </script>} and return
    else
      @is_create_retry = true
      render_new_presort_staging_run_child
    end
  rescue
    handle_error('record could not be created')
  end



  def edit_presort_staging_run_child
    return if authorise_for_web(program_name?,'edit')==false
    id = params[:id]
    if id && @presort_staging_run_child = PresortStagingRunChild.find(id)
      render_edit_presort_staging_run_child
    end
  end


  def render_edit_presort_staging_run_child
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit presort_staging_run_child'"%>

		<%= build_presort_staging_run_child_form(@presort_staging_run_child,'update_presort_staging_run_child','update_presort_staging_run_child',true)%>

		}, :layout => 'content'
  end

  def update_presort_staging_run_child
    id = params[:presort_staging_run_child][:id]
    @run_id=session[:active_doc]['presort_staging_run']
    #render :inline => %{
    #                      <script>
    #                        alert('order product edited');
    #
    #                        window.opener.frames[1].frames[0].location.reload(true);
    #                        window.opener.frames[1].document.getElementById("total_order_amount_cell").innerHTML= '<%= @total%>';
    #                        window.close();
    #                    </script>} and return
    if id && @presort_staging_run_child = PresortStagingRunChild.find(id)
      if @presort_staging_run_child.update_attributes(params[:presort_staging_run_child])
        @presort_staging_run_children = eval(session[:query])
        flash[:notice] = 'record saved'
        render :inline => %{
              <script>
              //window.opener.frames[1].frames[0].location.href = '/rmt_processing/presort_staging_run_child/list_presort_staging_run_children/<%=@run_id.to_s%>';
              //parent.location.href = '/rmt_processing/order/presort_staging_run/<%=@run_id.to_s%>';
               window.opener.frames[1].frames[0].location.reload(true);
              window.close();

              </script>
              }, :layout => 'content'
      else
        render_edit_presort_staging_run_child
      end
    end
  rescue
    handle_error('record could not be saved')
  end

  def search_dm_presort_staging_run_children
    return if authorise_for_web(program_name?,'read')== false
    dm_session['se_layout']              = 'content'
    @content_header_caption              = "'Search Pre sort staging run children'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form('search_presort_staging_run_children.yml', 'search_dm_presort_staging_run_children_grid')
  end


  def search_dm_presort_staging_run_children_grid
    @presort_staging_run_children = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @can_edit        = authorise(program_name?, 'edit', session[:user_id])
    @can_delete      = authorise(program_name?, 'delete', session[:user_id])
    @stat            = dm_session[:search_engine_query_definition]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]

    render :inline => %{
      <% grid            = build_presort_staging_run_child_dm_grid(@presort_staging_run_children, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
      <% grid.caption    = 'Pre sort staging run children' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end




end
