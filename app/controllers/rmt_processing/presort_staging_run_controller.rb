class  RmtProcessing::PresortStagingRunController < ApplicationController

  def program_name?
    "presort_staging_run"
  end

  def bypass_generic_security?
    true
  end



  def find_presort_runs
    return if authorise_for_web(program_name?,'read')== false
    dm_session['se_layout']              = 'content'
    @content_header_caption              = "'Search Pre sort staging runs'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form('search_presort_staging_runs.yml', 'search_presort_staging_runs_submit')
  end

  def search_presort_staging_runs_submit
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{dm_session[:search_engine_query_definition]}\")"
    session[:runs_type]="dm_query"
    @caption="'presort runs found'"
    render_list_presort_staging_runs
  end


  def show_bins_staged
    presort_staging_run=PresortStagingRun.find(params[:id])
    staged_bins=PresortStagingRun.bins_staged(params[:id])
    @bins=staged_bins[0]
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{staged_bins[1]}\")"
    @caption="'staged bins for #{presort_staging_run.presort_run_code}'"
    render_bins_grid
  end

  def location_farm_bins
    location_farm_code=params[:id].split("@")
    presort_staging_run=PresortStagingRun.find(session[:active_doc]['presort_staging_run'])
    bins_query=PresortStagingRun.get_bins_per_location_farm(location_farm_code[0],location_farm_code[1],presort_staging_run)
    @bins=bins_query[0]
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{bins_query[1]}\")"
    @caption="'bins available for LOCATION: #{location_farm_code[0]} and  FARM: #{location_farm_code[1]}'"
    render_bins_grid
  end

  def bins_available_locations
    presort_staging_run=PresortStagingRun.find(params[:id])
    locations_query=PresortStagingRun.get_available_locations(presort_staging_run)
    @locations=locations_query[0]
    #@locations.each do |location|
    #  bin_age =Location.bin_age(location)
    #  location['bin_age']=bin_age
    #  location['id']=presort_staging_run.id
    #end
    @locations = @locations.sort_by {|p| p.age }
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{locations_query[1]}\")"
    @caption="'available locations for #{presort_staging_run.presort_run_code}'"
    render_locations_grid
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

  def bins_available
    presort_staging_run=PresortStagingRun.find(params[:id])
    bins_query=PresortStagingRun.get_bins_available(presort_staging_run)

    @bins=bins_query[0]
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{bins_query[1]}\")"
    @caption="'bins available  for #{presort_staging_run.presort_run_code}'"
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


  def active_run
    presort_staging_run_id=session[:active_doc]['presort_staging_run'] if session[:active_doc]!=nil
    params[:id]=presort_staging_run_id
    if   presort_staging_run_id!= nil
      edit_presort_staging_run
      return
    else
      render :inline=>%{<script> alert('no current run'); </script>}, :layout=>'content'
    end
  end

  def edit_presort_staging_run
    return if authorise_for_web(program_name?, 'edit')==false
    @presort_staging_run=PresortStagingRun.find(params[:id])
    session[:run_status_b4_edit]= @presort_staging_run.status
    @can_edit = true
    set_active_doc("presort_staging_run",@presort_staging_run.id)
    render_edit_presort_staging_run
  end

  def render_edit_presort_staging_run
    render :inline => %{
  <% @content_header_caption = "'edit presort_staging_run'"%>
  <%= build_edit_presort_staging_run_form(@presort_staging_run,'update_presort_staging_run','update_presort_staging_run',@can_edit)%>
  }, :layout => 'content'
  end

  def staging_run_rmt_variety_code_changed
    rmt_variety_id= get_selected_combo_value(params)
    @season_codes=Season.find_by_sql("select seasons.id,seasons.season_code from seasons
                       inner join commodities on seasons.commodity_id=commodities.id
                       inner join rmt_varieties on rmt_varieties.commodity_id=commodities.id
                       where rmt_varieties.id=#{rmt_variety_id}") .map{|p|[p.season_code,p.id]}
    @season_codes.unshift("<empty>") if !@season_codes.empty?
    @track_slms_indicator_codes=TrackSlmsIndicator.find_by_sql("select track_slms_indicators.id,track_slms_indicators.track_slms_indicator_code from track_slms_indicators
                       inner join rmt_varieties on track_slms_indicators.rmt_variety_code=rmt_varieties.rmt_variety_code
                       where rmt_varieties.id=#{rmt_variety_id} and track_slms_indicators.track_indicator_type_code='RMI'") .map{|p|[p.track_slms_indicator_code,p.id]}
    @track_slms_indicator_codes.unshift("<empty>") if !@track_slms_indicator_codes.empty?

    @ripe_point_codes=RipePoint.find_by_sql("select distinct ripe_points.id,ripe_points.ripe_point_code
                                             from  rmt_varieties
                                             inner join varieties on varieties.rmt_variety_id=rmt_varieties.id
                                             inner join rmt_products on rmt_products.variety_id=varieties.id
                                             inner join ripe_points on rmt_products.ripe_point_id=ripe_points.id
                                             where rmt_varieties.id=#{rmt_variety_id}").map{|p|[p.ripe_point_code,p.id]}
    @ripe_point_codes.unshift("<empty>") if !@ripe_point_codes.empty?

    render :inline => %{
  <%= season_content = select('presort_staging_run','season_id',@season_codes)%>
  <%= track_slms_indicator_content =select('presort_staging_run','track_slms_indicator_id',@track_slms_indicator_codes)%>
  <%= ripe_point_content =select('presort_staging_run','ripe_point_id',@ripe_point_codes)%>
  <script>
  <%= update_element_function(
  "season_id_cell", :action => :update,
  :content => season_content) %>

  <%= update_element_function(
  "track_slms_indicator_id_cell", :action => :update,
  :content => track_slms_indicator_content) %>

  <%= update_element_function(
  "ripe_point_id_cell", :action => :update,
  :content => ripe_point_content) %>
  </script>
  }

  end


  def new_presort_run
    return if authorise_for_web(program_name?,'create')== false
    render_new_presort_staging_run
  end

  def render_new_presort_staging_run
#	 render (inline) the edit template
    render :inline => %{
<% @content_header_caption = "'create new presort_staging_run'"%>

<%= build_presort_staging_run_form(@presort_staging_run,'create_presort_staging_run','create_presort_staging_run',false,@is_create_retry)%>

}, :layout => 'content'
  end

  def create_presort_staging_run
    @presort_staging_run = PresortStagingRun.new(params[:presort_staging_run])
    if @presort_staging_run.save
      StatusMan.set_status("EDITING","presort_staging_run",@presort_staging_run,session[:user_id].user_name)
      set_active_doc("presort_staging_run",@presort_staging_run.id)
      params[:id] = @presort_staging_run.id
      edit_presort_staging_run
    else
      @is_create_retry = true
      render_new_presort_staging_run
    end
  rescue
    handle_error('record could not be created')
  end

  def get_runs(status=nil)
    if status
    list_query = "select p.*,pc.product_class_code ,tm.treatment_code,sizes.size_code,
     s.season_code,f.farm_group_code,r.rmt_variety_code,t.track_slms_indicator_code ,ripe_points.ripe_point_code
     from presort_staging_runs p
     inner join seasons s on p.season_id=s.id
     inner join farm_groups f on p.farm_group_id=f.id
     inner join rmt_varieties r on p.rmt_variety_id=r.id
     inner join track_slms_indicators t on p.track_slms_indicator_id=t.id
     inner join ripe_points on p.ripe_point_id=ripe_points.id
     left  join product_classes pc on p.product_class_id=pc.id
     left  join  treatments tm on p.treatment_id=tm.id
     left  join  sizes on p.size_id=sizes.id
     where p.status='#{status}' order by p.id desc"
    else
      list_query = "select p.*,pc.product_class_code ,tm.treatment_code,sizes.size_code,
     ripe_points.ripe_point_code,     s.season_code,f.farm_group_code,r.rmt_variety_code,t.track_slms_indicator_code
     from presort_staging_runs p
     inner join seasons s on p.season_id=s.id
     inner join farm_groups f on p.farm_group_id=f.id
     inner join rmt_varieties r on p.rmt_variety_id=r.id
     inner join track_slms_indicators t on p.track_slms_indicator_id=t.id order by p.id desc
     inner join ripe_points on p.ripe_point_id=ripe_points.id
     left  join product_classes pc on p.product_class_id=pc.id
     left  join  treatments tm on p.treatment_id=tm.id
     left  join sizes on p.size_id=sizes.id"
    end

    session[:query]="ActiveRecord::Base.connection.select_all(\"#{list_query}\")"
  end

  def staged_presort_runs
    return if authorise_for_web(program_name?,'read') == false
    get_runs("STAGED")
    @caption="'staged presort runs'"
    session[:runs_type]="staged"
    render_list_presort_staging_runs
  end

  def active_presort_runs
    return if authorise_for_web(program_name?,'read') == false
    get_runs("ACTIVE")
    session[:runs_type]="active"
    @caption="'active presort runs'"
    render_list_presort_staging_runs
  end

  def editing_presort_runs
    return if authorise_for_web(program_name?,'read') == false
    get_runs("EDITING")
    session[:runs_type]="editing"
    @caption="'editing presort runs'"
    render_list_presort_staging_runs
  end


  def render_list_presort_staging_runs
    @pagination_server = "list_presort_staging_runs"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:presort_staging_runs_page]
    @current_page = params['page']||= session[:presort_staging_runs_page]
    @presort_staging_runs =  eval(session[:query]) if !@presort_staging_runs
    render :inline => %{
  <% grid = build_presort_staging_run_grid(@presort_staging_runs,@can_edit,@can_delete)%>
  <% grid.caption = @caption%>
  <% @header_content = grid.build_grid_data %>

  <% @pagination = pagination_links(@presort_staging_run_pages) if @presort_staging_run_pages != nil %>
  <%= grid.render_html %>
  <%= grid.render_grid %>
  },:layout => 'content'
  end

  def search_presort_staging_runs_flat
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true
    render_presort_staging_run_search_form
  end

  def render_presort_staging_run_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
<% @content_header_caption = "'search  presort_staging_runs'"%>

<%= build_presort_staging_run_search_form(nil,'submit_presort_staging_runs_search','submit_presort_staging_runs_search',@is_flat_search)%>

}, :layout => 'content'
  end




  def delete_presort_staging_run
    return if authorise_for_web(program_name?,'delete')== false
    if params[:page]
      session[:presort_staging_runs_page] = params['page']
      active_presort_runs  if session[:runs_type]=="active"
      editing_presort_runs if session[:runs_type]=="editing"
      staged_presort_runs  if session[:runs_type]=="staged"
      search_presort_staging_runs_submit if   session[:runs_type]=="dm_query"
      return
    end
    id = params[:id]
    if id && presort_staging_run = PresortStagingRun.find(id)
      presort_staging_run.destroy
      session[:alert] = ' Record deleted.'
      active_presort_runs  if session[:runs_type]=="active"
      editing_presort_runs if session[:runs_type]=="editing"
      staged_presort_runs  if session[:runs_type]=="staged"
      search_presort_staging_runs_submit if   session[:runs_type]=="dm_query"
    end
  rescue
    handle_error('record could not be deleted')
  end

  def check_for_active_run
    active_run=nil
    active_run=PresortStagingRun.find_by_status("ACTIVE")
    return active_run
  end

  def update_presort_staging_run
    id = params[:presort_staging_run][:id]
    @presort_staging_run = PresortStagingRun.find(id)
    begin
      if  session[:run_status_b4_edit]!= params[:presort_staging_run][:status]
        if params[:presort_staging_run][:status]=="ACTIVE"
          active_run=check_for_active_run
          if active_run
            params[:id] = @presort_staging_run.id
            flash[:error] = 'status cannot be changed,another run already active'
            render_edit_presort_staging_run and return
          end
        end
      end
      if  params[:presort_staging_run].include?('farm_group_id') && (@presort_staging_run.farm_group_id.to_i != params[:presort_staging_run][:farm_group_id].to_i )
        bins_staged=PresortStagingRun.bins_staged(@presort_staging_run.id)[0].length
        active_children=PresortStagingRunChild.active_chidren(@presort_staging_run.id).length
        editing_children=PresortStagingRunChild.editing_chidren(@presort_staging_run.id).length
        if bins_staged > 0 && active_children > 0
          params[:id] = @presort_staging_run.id
          flash[:error] = 'farm_group cannot be edited ,there are chidren staged and one is active'
          render_edit_presort_staging_run and return
        elsif  editing_children > 0
          params[:id] = @presort_staging_run.id
          flash[:error] = 'farm_group cannot be edited ,there are chidren editing '
          render_edit_presort_staging_run and return
        elsif  active_children > 0
          params[:id] = @presort_staging_run.id
          flash[:error] = 'farm_group cannot be edited ,there is an active child '
          render_edit_presort_staging_run and return
        #else
        #  flash[:error] = 'delete children first before changing the farm group '
        #  render_edit_presort_staging_run and return

        end

      end
      if id && @presort_staging_run
        if @presort_staging_run.update_attributes(params[:presort_staging_run])
          if  session[:run_status_b4_edit]!= params[:presort_staging_run][:status]
            StatusMan.set_status(params[:presort_staging_run][:status],"presort_staging_run",@presort_staging_run,session[:user_id].user_name)
          end
          params[:id] = @presort_staging_run.id
          flash[:notice] = 'record saved'
          if @presort_staging_run.status == 'EDITING'

          else

          end
          edit_presort_staging_run
        else
          render_edit_presort_staging_run
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end




  def search_dm_presort_staging_runs_grid
    @presort_staging_runs = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @can_edit        = authorise(program_name?, 'edit', session[:user_id])
    @can_delete      = authorise(program_name?, 'delete', session[:user_id])
    @stat            = dm_session[:search_engine_query_definition]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]

    render :inline => %{
<% grid            = build_presort_staging_run_dm_grid(@presort_staging_runs, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
<% grid.caption    = 'Pre sort staging runs' %>
<% @header_content = grid.build_grid_data %>
<%= grid.render_html %>
<%= grid.render_grid %>
}, :layout => 'content'
  end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: track_slms_indicator_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: farm_group_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: season_id
#	---------------------------------------------------------------------------------
  def presort_staging_run_season_code_changed
    season_code = get_selected_combo_value(params)
    session[:presort_staging_run_form][:season_code_combo_selection] = season_code
    @commodity_codes = PresortStagingRun.commodity_codes_for_season_code(season_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
<%= select('presort_staging_run','commodity_code',@commodity_codes)%>

}

  end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: rmt_variety_id
#	---------------------------------------------------------------------------------
  def presort_staging_run_commodity_code_changed
    commodity_code = get_selected_combo_value(params)
    session[:presort_staging_run_form][:commodity_code_combo_selection] = commodity_code
    @rmt_variety_codes = PresortStagingRun.rmt_variety_codes_for_commodity_code(commodity_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
<%= select('presort_staging_run','rmt_variety_code',@rmt_variety_codes)%>

}

  end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: farm_id
#	---------------------------------------------------------------------------------


end
