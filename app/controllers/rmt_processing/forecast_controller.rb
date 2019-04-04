class RmtProcessing::ForecastController < ApplicationController

  def program_name?
    "forecast"
  end

  def bypass_generic_security?
    true
  end

#===========================
#   File Strucure Test   ===
#===========================

  def farm_changed
      farm_code= get_selected_combo_value(params)

       pucs = ActiveRecord::Base.connection.select_all("
              select distinct p.id ,p.puc_code
              from pucs p
              join farm_puc_accounts fpa on fpa.puc_id = p.id
              where fpa.farm_code = '#{farm_code}'
             ")

       pucs = pucs.map{|x|x['puc_code']}  if !pucs.empty?

      @pucs = pucs.unshift("<empty>")

      render :inline => %{

             <% puc_content = select('forecast','puc_code', @pucs) %>
             <script>
               <%= update_element_function(
                    "puc_code_cell", :action => :update,
                    :content => puc_content) %>
              </script>
  }
  end


  def file_structure
    #@root_file = "C:/App_factory/app_factory"
    #@root_file = "C:/Documents and Settings/Luxolo Matoti/My Documents/Exercises"
    @root_file     = "C:/reports_yml"
    #@root_file = "C:/current projects/Kromco mes"
    #@root_file = "C:/Documents and Settings/Luxolo Matoti/My Documents/My Pictures"

#_______________________________________________________________
    tree_builder   = ReportTreeBuilder.new
    @tree          = tree_builder.build_tree(@root_file) # Store in session state to rebuild location of selected file
    session[:tree] = @tree
#________________________________________________________________

    render :inline => %{
                     <%  @content_header_caption = "'#{@root_file}'" %>
                     <% @tree_script = build_file_structure_form(@tree,@tree[0].values[0]) %>
                     }, :layout => 'tree'
  end

  def build_happymores_form
    tree_builder = ReportTreeBuilder.new
    url          = tree_builder.get_file_location(session[:tree], params[:id].to_s)
    #----------Generic method in app controller - By Happy
    build_parameters_form(url)
    #--------------------end-----------------------------
  end

#============================================================
  def list_forecasts
    if params[:page]!= nil

      session[:forecasts_page] = params['page']

      render_list_forecasts

      return
    else
      session[:forecasts_page] = nil
    end

    list_query      = "@forecast_pages = Paginator.new self, Forecast.count, @@page_size,@current_page
	 @forecasts = Forecast.find(:all,
				 :limit => @forecast_pages.items_per_page,
				 :offset => @forecast_pages.current.offset,:order => 'farm_code ASC')"
    session[:query] = list_query
    render_list_forecasts
  end


  def render_list_forecasts
    @can_edit   = authorise(program_name?, 'forecast_edit', session[:user_id])
    @can_delete = authorise(program_name?, 'forecast_delete', session[:user_id])
    @current_page = session[:forecasts_page] if session[:forecasts_page]
    @current_page = params['page'] if params['page']
    @forecasts = eval(session[:query]) if !@forecasts 
    @content_header_caption = "'list of found forecast headers'"
    render :inline => %{
      <% grid            = build_forecast_grid(@forecasts,@can_edit,@can_delete) %>
      <% grid.caption    = 'forecasts' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@forecast_pages) if @forecast_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def render_forecast_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  forecasts'"%> 

		<%= build_forecast_search_form(nil,'submit_forecasts_search','submit_forecasts_search',@is_flat_search)%>

		}, :layout => 'content'
  end

#def render_forecast_search_form(is_flat_search = nil)
#	session[:is_flat_search] = @is_flat_search
##	 render (inline) the search form
#	render :inline => %{
#		<% @content_header_caption = "'search  forecasts'"%>
#
#		<%= build_forecast_search_form(nil,'submit_forecasts_search','submit_forecasts_search',@is_flat_search)%>
#
#		}, :layout => 'content'
#end

  def search_forecasts
    dm_session[:parameter_fields_values] = nil
    dm_session['se_layout']              = 'content'
    @content_header_caption           = "'search forecast headers'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form("search_forecast_headers.yml", "submit_forecasts_search")
  end

  def submit_forecasts_search
    l=dm_session[:search_engine_query_definition]
    session[:query] = "ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])"
    @forecasts = eval(session[:query])
    if (@forecasts.length > 0)
      render_found_forecasts
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                            </script>
                          }, :layout => 'content'
    end
  end

  def render_found_forecasts
    if @forecasts !=nil and @forecasts.length > 0
      ids = []
      @forecasts_list = []
      @forecasts.each do |forecast|
        if(!ids.include?(forecast["id"]))
          ids.push(forecast["id"])
          @forecasts_list.push(forecast)
        end
      end

      @can_edit   = authorise(program_name?, 'forecast_edit', session[:user_id])
      @can_delete = authorise(program_name?, 'forecast_delete', session[:user_id])
      render :inline => %{
        <% grid            = build_list_forecast_headers_grid(@forecasts_list,@can_edit,@can_delete) %>
        <% grid.caption    = '' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
    else
      redirect_to_index("'no forecast records to list'", "''")
    end
  end

  def delete_forecast
    begin
      return if authorise_for_web(program_name?, 'forecast_delete')== false

      id = params[:id]
      if id && forecast = Forecast.find(id)
        if (!forecast.tickets_printed_datetime)
          forecast.destroy
          session[:alert] = " Record deleted."
          redirect_to_index("'forecast header deleted successfully'", "''")
        else
          flash[:error] = " Record deleted could not be deleted: some bin tickets have been printed for this forecast."
          redirect_to_index()
        end
      end
    rescue
      handle_error('record could not be deleted')
    end
  end

  def new_forecast
    return if authorise_for_web(program_name?, 'forecast_new')== false
    render_new_forecast
  end

#   ======================================
#   method to generate the sequence number
#   ======================================
  def generate_sequence_number(forecast)
    if Forecast.find_by_sql("select max(sequence_number) as max_sequence from forecasts where farm_code = '#{forecast.farm_code}' and season = '#{forecast.season}' and forecast_type_code = '#{forecast.forecast_type_code}'") != nil
      max_sequence_number_arra = Forecast.find_by_sql("select max(sequence_number) as max_sequence from forecasts where farm_code = '#{forecast.farm_code}' and season = '#{forecast.season}' and forecast_type_code = '#{forecast.forecast_type_code}'")
      max_sequence_number      = max_sequence_number_arra[0].max_sequence.to_i
    else
      max_sequence_number = 0
    end

    return max_sequence_number
  end

  def create_forecast
    begin
      @forecast                      = Forecast.new(params[:forecast])
      @forecast.sequence_number      = generate_sequence_number(@forecast) + 1
      @forecast.forecast_status_code = "active"
      @forecast.puc_id             = Puc.find_by_puc_code(params[:forecast]['puc_code']).id if params[:forecast]['puc_code']
#   ========================
#   generating forecast_code
#   ========================
      @forecast.forecast_code        = @forecast.forecast_type_code + "_" + @forecast.season.to_s + "_" + @forecast.farm_code + "_" + @forecast.sequence_number.to_s
#   ========================
      if @forecast.save
        params[:id] = @forecast.id
        edit_forecast
      else
        @is_create_retry = true
        render_new_forecast
      end
    rescue
      handle_error('record could not be created')
    end

  end

  def render_new_forecast
    @action  = 'create_forecast'
    @caption = 'create_forecast'
    render :inline => %{
		<% @content_header_caption = "'create new forecast'"%> 

		<%= build_forecast_form(@forecast,@action,@caption,false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_forecast
#    return if authorise_for_web(program_name?, 'forecast_edit')==false
    #@params_hash =  { "paraSeason_code" => "2007_AP","paraFarm_code" => "0A" }
    @can_edit   = true
    id = params[:id]
    if id && @forecast = Forecast.find(id)
      session[:forecast_id]  = @forecast.id
      @track_slms_indicators = @forecast.track_slms_indicators
      render_edit_forecast

    end
  end

  def view_forecast
    @can_print_bin_tickets = authorise(program_name?, 'forecast_print_bin_tickets', session[:user_id])
    @can_edit = authorise(program_name?, 'forecast_edit', session[:user_id])
    @is_view = true
    id = params[:id]
    if id && @forecast = Forecast.find(id)
      session[:forecast_id]  = @forecast.id
      @track_slms_indicators = @forecast.track_slms_indicators
      render_edit_forecast

    end
  end

## ==============================
## Luks render_edit_forecast
## ==============================
  def render_edit_forecast
    @action                 = 'update_forecast'
    @caption                = 'update_forecast'
    @farm_codes             = Farm.find_by_sql('select distinct farm_code from farms').map { |g| [g.farm_code] }
    @seasons                = Season.find_by_sql('select distinct season from seasons').map { |g| [g.season] }
    @pucs                   = Puc.find_by_sql("select puc_code from pucs").map { |g| [g.puc_code] }
    session[:forecast_id]   = @forecast.id
    @content_header_caption = "'edit forecast'"
    render :template => "rmt_processing/forecast/edit_forecast", :layout => "content"
  end

  def update_forecast
    begin
      if params[:page]
        session[:forecasts_page] = params['page']
        render_list_forecasts
        return
      end

      @current_page = session[:forecasts_page]
      id            = session[:forecast_id] #params[:id]
      if id && @forecast = Forecast.find(id)
        begin
          @forecast.puc_id             = Puc.find_by_puc_code(params[:forecast]['puc_code']).id if params[:forecast]['puc_code']
          @forecast.update_attributes(params[:forecast])
          @forecasts            = eval(session[:query])
          flash[:notice]        = 'record saved'
          session[:forecast_id] = @forecast.id
          active_forecast
        rescue
          #render_edit_forecast
          flash[:error] = 'forecast could not be edited'
          render :inline => %{}, :layout => 'content'
        end
      end
    rescue
      handle_error('record could not be saved')
    end

  end

#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(forecasts)
#	-----------------------------------------------------------------------------------------------------------
  def forecast_season_search_combo_changed
    season                                                  = get_selected_combo_value(params)
    session[:forecast_search_form][:season_combo_selection] = season
    @farm_codes                                             = Forecast.find_by_sql("Select distinct farm_code from forecasts where season = '#{season}'").map { |g| [g.farm_code] }
    @farm_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('forecast','farm_code',@farm_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_forecast_farm_code'/>
		<%= observe_field('forecast_farm_code',:update => 'forecast_code_cell',:url => {:action => session[:forecast_search_form][:farm_code_observer][:remote_method]},:loading => "show_element('img_forecast_farm_code');",:complete => session[:forecast_search_form][:farm_code_observer][:on_completed_js])%>
		}

  end


  def forecast_farm_code_search_combo_changed
    farm_code                                                  = get_selected_combo_value(params)
    session[:forecast_search_form][:farm_code_combo_selection] = farm_code
    season                                                     = session[:forecast_search_form][:season_combo_selection]
    @forecast_codes                                            = Forecast.find_by_sql("Select distinct forecast_code from forecasts where farm_code = '#{farm_code}' and season = '#{season}'").map { |g| [g.forecast_code] }
    @forecast_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('forecast','forecast_code',@forecast_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_forecast_forecast_code'/>
		<%= observe_field('forecast_forecast_code',:update => 'forecast_status_code_cell',:url => {:action => session[:forecast_search_form][:forecast_code_observer][:remote_method]},:loading => "show_element('img_forecast_forecast_code');",:complete => session[:forecast_search_form][:forecast_code_observer][:on_completed_js])%>
		}

  end


  def forecast_forecast_code_search_combo_changed
    forecast_code                                                  = get_selected_combo_value(params)
    session[:forecast_search_form][:forecast_code_combo_selection] = forecast_code
    farm_code                                                      = session[:forecast_search_form][:farm_code_combo_selection]
    season                                                         = session[:forecast_search_form][:season_combo_selection]
    @forecast_status_codes                                         = Forecast.find_by_sql("Select distinct forecast_status_code from forecasts where forecast_code = '#{forecast_code}' and farm_code = '#{farm_code}' and season = '#{season}'").map { |g| [g.forecast_status_code] }
    @forecast_status_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('forecast','forecast_status_code',@forecast_status_codes)%>

		}

  end

#   ==========================
#   Add track indicator method
#   ==========================
  def add_track_indicator
    @forecast = Forecast.find(params[:id])
    #session[:forecast_id] = @forecast.id

    render :inline => %{
		<% @content_header_caption = "'add track slms indicator for forecast: " + @forecast.id.to_s + ": farm:" + @forecast.farm_code + ", season: " + @forecast.season.to_s + " '"%>

		<%= build_track_indicator_form(@forecasts_track_slms_indicator,'save_forecasts_track_slms_indicator','save')%>

		}, :layout => 'content'
  end

#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(forecasts_track_slms_indicators)
#	-----------------------------------------------------------------------------------------------------------
  def forecasts_track_slms_indicator_commodity_code_search_combo_changed
    commodity_code                                                                        = get_selected_combo_value(params)
    session[:forecasts_track_slms_indicator_search_form][:commodity_code_combo_selection] = commodity_code
    @variety_codes                                                                        = TrackSlmsIndicator.find_by_sql("Select distinct variety_code from track_slms_indicators where commodity_code = '#{commodity_code}' and variety_type = 'rmt_variety'").map { |g| [g.variety_code] }
    @variety_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('forecasts_track_slms_indicator','variety_code',@variety_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_forecasts_track_slms_indicator_variety_code'/>
		<%= observe_field('forecasts_track_slms_indicator_variety_code',:update => 'track_slms_indicator_code_cell',:url => {:action => session[:forecasts_track_slms_indicator_search_form][:variety_code_observer][:remote_method]},:loading => "show_element('img_forecasts_track_slms_indicator_variety_code');",:complete => session[:forecasts_track_slms_indicator_search_form][:variety_code_observer][:on_completed_js])%>
		}

  end


  def forecasts_track_slms_indicator_variety_code_search_combo_changed

    variety_code                                                                        = get_selected_combo_value(params)
    session[:forecasts_track_slms_indicator_search_form][:variety_code_combo_selection] = variety_code
    commodity_code                                                                      = session[:forecasts_track_slms_indicator_search_form][:commodity_code_combo_selection]
    @track_slms_indicator_codes                                                         = TrackSlmsIndicator.find_by_sql("Select distinct track_slms_indicator_code from track_slms_indicators where variety_type = 'rmt_variety' and variety_code = '#{variety_code}' and commodity_code = '#{session[:forecasts_track_slms_indicator_search_form][:commodity_code_combo_selection]}'").map { |g| [g.track_slms_indicator_code] }
    @track_slms_indicator_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('forecasts_track_slms_indicator','track_slms_indicator_code',@track_slms_indicator_codes)%>

		}

  end

  def save_forecasts_track_slms_indicator
# ===============================================
# saves a forecast's track_slms_indicators record
# ===============================================
    forecast                  = Forecast.find(session[:forecast_id])
    commodity_code            = params[:forecasts_track_slms_indicator][:commodity_code]
    variety_code              = params[:forecasts_track_slms_indicator][:variety_code]
    track_slms_indicator_code = params[:forecasts_track_slms_indicator][:track_slms_indicator_code]
    track_slms_indicator      = TrackSlmsIndicator.find(:first, :conditions =>['commodity_code = ? and variety_code = ? and track_slms_indicator_code = ? ', commodity_code, variety_code, track_slms_indicator_code])

    if track_slms_indicator != nil && !forecast.track_slms_indicators.include?(track_slms_indicator)
      forecast.add_track_slms_indicator(track_slms_indicator)
    elsif (forecast.track_slms_indicators.include?(track_slms_indicator))
      flash[:error] = "Forecast already has track this indicator"
    else
      flash[:error] = "Sorry, track indicator is invalid"
    end
# ===============================================
    params[:id] = forecast.id
    edit_forecast

  end

  def remove_forecast_track_indicator
    forecast = Forecast.find(session[:forecast_id])

    for track_slms_indicator in forecast.track_slms_indicators
      if track_slms_indicator.id.to_s == params[:id]
        forecast.track_slms_indicators.delete(track_slms_indicator)
      end
    end
    # ===============================================
    params[:id] = forecast.id
    edit_forecast
  end

  def add_forecast_variety
    #@forecast = Forecast.find(params[:id])
    @forecast = Forecast.find(session[:forecast_id])

    render :inline => %{
		<% @content_header_caption = "'create forecast variety record for forecast: " + @forecast.id.to_s + ": farm:" + @forecast.farm_code + ", season: " + @forecast.season.to_s + " '"%>

		<%= build_forecast_variety_form(@forecast_variety,'save_forecast_variety','save_forecast_variety')%>

		}, :layout => 'content'
  end

#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(forecasts_varieties)
#	-----------------------------------------------------------------------------------------------------------
  def forecast_variety_commodity_code_combo_changed
    commodity_code                                                   = get_selected_combo_value(params)
    session[:forecast_variety_form][:commodity_code_combo_selection] = commodity_code
    @rmt_variety_codes                                               = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}'").map { |g| [g.rmt_variety_code] }
    @rmt_variety_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		                <%= select('forecast_variety','rmt_variety_code',@rmt_variety_codes)%>

	    		       }

  end

  def calculate_quantity_sum(forecast_variety)
    quantity_sum = 0

    if forecast_variety.forecast_variety_indicators != nil
      for forecast_variety_indicator in forecast_variety.forecast_variety_indicators
        quantity_sum += forecast_variety_indicator.quantity
      end
    end

    return quantity_sum
  end

  def return_to_forecast_edit_header

    forecast    = Forecast.find(session[:forecast_id])
    params[:id] = forecast.id
    edit_forecast

  end

  def save_forecast_variety
    @forecast_variety             = ForecastVariety.new(params[:forecast_variety])
    quantity                      = calculate_quantity_sum(@forecast_variety)
    @forecast                     = Forecast.find(session[:forecast_id])
    @forecast_variety.forecast_id = @forecast.id

    @forecast_variety.quantity = 0 if @forecast_variety.quantity == nil
    if quantity <= @forecast_variety.quantity
      if quantity == @forecast_variety.quantity
        @forecast_variety.status_code = "balanced"
      else #if quantity < @forecast_variety.quantity
        @forecast_variety.status_code = "unbalanced"
      end

      if (@forecast.has_forecast_variety?(@forecast_variety))
        flash[:error] = 'forecast already has such a variety'
        add_forecast_variety
      elsif @forecast_variety.save
        flash[:notice] = 'new forecast variety record created successfully'
        return_to_forecast_edit_header
      else
        flash[:error] = 'new forecast variety record COULD NOT BE CREATED'
        add_forecast_variety
      end
    else
      flash[:error] = 'quantities of indicators bigger than total entered'
      render :inline => %{
        <% @content_header_caption = "'create forecast variety record for forecast: " + @forecast.id.to_s + ": farm:" + @forecast.farm_code + ", season: " + @forecast.season.to_s + " '"%>

        <%= build_forecast_variety_form(@forecast_variety,'save_forecast_variety','save_forecast_variety')%>

        }, :layout => 'content'
    end
  end

  def edit_forecast_variety
    @forecast_variety          = ForecastVariety.find(params[:id])
    session[:forecast_variety] = @forecast_variety.id
    @forecast                  = Forecast.find(session[:forecast_id])

    render :inline => %{
		<% @content_header_caption = "'create forecast variety record for forecast: " + @forecast.id.to_s + ": farm:" + @forecast.farm_code + ", season: " + @forecast.season.to_s + " '"%>

		<%= build_forecast_variety_form(@forecast_variety,'update_forecast_variety','update_forecast_variety')%>

		}, :layout => 'content'
  end

  def update_forecast_variety
    @forecast_variety             = ForecastVariety.find(session[:forecast_variety])
    edited_forecast_variety       = ForecastVariety.new(params[:forecast_variety])
    quantity                      = calculate_quantity_sum(@forecast_variety)
    @forecast                     = Forecast.find(session[:forecast_id])
    @forecast_variety.forecast_id = @forecast.id

    if @forecast_variety.quantity != nil
      if quantity <= edited_forecast_variety.quantity #@forecast_variety.quantity

        if quantity == edited_forecast_variety.quantity #@forecast_variety.quantity
          @forecast_variety.status_code = "balanced"
          #edited_forecast_variety.status_code= "balanced"
        else
          @forecast_variety.status_code = "unbalanced"
          #edited_forecast_variety.status_code = "unbalanced"
        end

        if @forecast_variety.update_attributes(params[:forecast_variety])

          flash[:notice] = 'forecast variety record has been updated successfully '

          return_to_forecast_edit_header
        else
          flash[:error] = 'forecast variety record COULD NOT BE UPDATED'
          return_to_forecast_edit_header
        end

      else
        flash[:error] = 'quantities of indicators bigger than total entered'

        render :inline => %{
		<% @content_header_caption = "'edit forecast variety record for forecast: " + @forecast.id.to_s + ": farm:" + @forecast.farm_code + ", season: " + @forecast.season.to_s + " '"%>

		<%= build_forecast_variety_form(@forecast_variety,'update_forecast_variety','update_forecast_variety')%>

		}, :layout => 'content'
        # REDIRECTING TO edit_forecast_variety
      end
    else
      flash[:error] = 'Please enter a valid quantity value'

      render :inline => %{
		<% @content_header_caption = "'edit forecast variety record for forecast: " + @forecast.id.to_s + ": farm:" + @forecast.farm_code + ", season: " + @forecast.season.to_s + " '"%>

		<%= build_forecast_variety_form(@forecast_variety,'update_forecast_variety','update_forecast_variety')%>

		}, :layout => 'content'
    end

  end

  def delete_forecast_variety
    id = params[:id]
    if id && forecast_variety = ForecastVariety.find(id)
      forecast_variety.destroy
      flash[:notice] = " Forecast Variety Record deleted."

    else
      flash[:error] = "This Forecast Variety Record does not exist !!!"
    end

    return_to_forecast_edit_header
  end

  def add_forecast_variety_indicator
    id                         = params[:id]
    @forecast_variety          = ForecastVariety.find(id)
    session[:forecast_variety] = @forecast_variety.id

    render :inline => %{
		<% @content_header_caption = "'create forecast variety indicator record for forecast variety: " + @forecast_variety.rmt_variety_code + " '"%>

		<%= build_forecast_variety_indicator_form(@forecast_variety_indicator,'save_forecast_variety_indicator','save_forecast_variety_indicator')%>

		}, :layout => 'content'
  end

  def save_forecast_variety_indicator
    @forecast_variety_indicator = ForecastVarietyIndicator.new(params[:forecast_variety_indicator])
    @forecast_variety           = ForecastVariety.find(session[:forecast_variety])
    quantity                    = calculate_quantity_sum(@forecast_variety)

    @forecast_variety_indicator.quantity = @forecast_variety_indicator.quantity.to_i if !@forecast_variety_indicator.quantity.kind_of?(Fixnum) # if user does not
    # fill in the quantity field
    # i.e. the form submits a nil value
    quantity = quantity + @forecast_variety_indicator.quantity

    #VALIDATION RULE
    if quantity > @forecast_variety.quantity
      flash[:error] = 'quantities of indicators bigger than total entered'
      return_to_forecast_edit_header
    else
      if quantity == @forecast_variety.quantity
        @forecast_variety.status_code = "balanced"
      else
        @forecast_variety.status_code = "unbalanced"
      end

      @forecast_variety_indicator.forecast_variety_id    = @forecast_variety.id
      @forecast_variety_indicator.number_tickets_printed = 0

      if  @forecast_variety.update_attributes(@forecast_variety.attributes)
        if !@forecast_variety.has_forecast_variety_indicator?(@forecast_variety_indicator) && @forecast_variety_indicator.save

          flash[:notice] = 'forecast_variety_indicator record saved successfully'
          return_to_forecast_edit_header

        else

          flash[:error] = 'forecast_variety already has this forecast_variety_indicator'

          render :inline => %{
		<% @content_header_caption = "'create forecast variety indicator record for forecast variety: " + @forecast_variety.rmt_variety_code + " '"%>

		<%= build_forecast_variety_indicator_form(@forecast_variety_indicator,'save_forecast_variety_indicator','save_forecast_variety_indicator')%>

		}, :layout => 'content'
        end
      end
    end
  end

  def set_quantities
    @forecast                  = Forecast.find(session[:forecast_id])
    @forecast_variety          = ForecastVariety.find(params[:id])
    session[:forecast_variety] = params[:id]
    @content_header_caption    = "'forecast: forecast"+ @forecast.id.to_s + "season:" + @forecast.season.to_s + " farm:" + @forecast.farm_code + " rmt variety: " + @forecast_variety.rmt_variety_code + "'"

#   ========================
    @quantity_list             = build_forecast_variety_quantity_list(@forecast_variety)
#   ========================

    render :template => "rmt_processing/forecast/set_quantities", :layout => "content"
  end

  def calculate_quantities
    builder               = ObjectBuilder.new
    @quantity_list_object = builder.build_hash_object(params[:quantity_list])

    @percentage_sum       = 0
    for attr in @quantity_list_object.attribute_names
      @percentage_sum += params[:quantity_list][attr].to_i
    end

    if @percentage_sum == 100

      #  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      for attr in @quantity_list_object.attribute_names
        id                         = attr.delete("_")
        percentage                 = eval("@quantity_list_object." + attr).to_i

        forecast_variety_indicator = ForecastVarietyIndicator.find(id.to_i)
        new_quantity               = Float.round_float(0, (percentage.to_f/100.to_f) * forecast_variety_indicator.forecast_variety.quantity.to_f).to_i
        forecast_variety_id        = forecast_variety_indicator.forecast_variety.id
        forecast_variety_indicator.update_attribute(:quantity, new_quantity)
      end
      #  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

      begin
        forecast_variety             = ForecastVariety.find(forecast_variety_id)
        forecast_variety.status_code = "balanced"
        forecast_variety.update_attributes(forecast_variety.attributes)
      rescue
        flash[:error] = "---Status update ERROR---" + forecast_variety_id.to_s
      end
      return_to_forecast_edit_header
    else
      flash[:error]           = "the sum does NOT equal to 100%,please balance again"

      @forecast               = Forecast.find(session[:forecast_id])
      @forecast_variety       = ForecastVariety.find(session[:forecast_variety])

      @content_header_caption = "'forecast: forecast"+ @forecast.id.to_s + "season:" + @forecast.season.to_s + " farm:" + @forecast.farm_code + " rmt variety: " + @forecast_variety.rmt_variety_code + "'"

#   ========================
      @quantity_list          = @quantity_list_object
#   ========================

      render :template => "rmt_processing/forecast/set_quantities", :layout => "content"


    end

  end

#def build_forecast_variety_quantity_list(forecast_variety)
#
#   @quantity_list_hash_string = "{"
#    for forecast_variety_indicator in forecast_variety.forecast_variety_indicators
#      percentage = Float.round_float(0,(forecast_variety_indicator.quantity.to_f / forecast_variety.quantity.to_f) * 100).to_i
#      id = "_" + forecast_variety_indicator.id.to_s
#      #puts id + " => " + percentage.to_s
#      @quantity_list_hash_string += " '#{id}' => '#{percentage}', "
#    end
#   @quantity_list_hash_string += "}"
#
#   @quantity_list_hash = Hash.new
#   @quantity_list_hash = eval(@quantity_list_hash_string)
#
#   builder = ObjectBuilder.new
#   @quantity_list_object = builder.build_hash_object(@quantity_list_hash)
#
#   return @quantity_list_object
#end

  def build_forecast_variety_quantity_list(forecast_variety)
    @quantity_list_hash = Hash.new

    for forecast_variety_indicator in forecast_variety.forecast_variety_indicators
      percentage              = Float.round_float(0, (forecast_variety_indicator.quantity.to_f / forecast_variety.quantity.to_f) * 100).to_i
      id                      = "_" + forecast_variety_indicator.id.to_s
      @quantity_list_hash[id] = percentage.to_s
    end
#puts "forecast_variety_indicator? " + @quantity_list_hash.length.to_s
    builder = ObjectBuilder.new

    if @quantity_list_hash.length == 0
      return nil
    else
      @quantity_list_object = builder.build_hash_object(@quantity_list_hash)
      return @quantity_list_object
    end


  end

  def add_forecast_variety_indicators_track_slms_indicator
    @forecast                            = Forecast.find(session[:forecast_id])
    @forecast_variety_indicator          = ForecastVarietyIndicator.find(params[:id])
    session[:forecast_variety_indicator] = @forecast_variety_indicator.id
    @commodity_code                      = @forecast_variety_indicator.forecast_variety.commodity_code

    render :inline => %{
		<% @content_header_caption = "'add track slms indicator for forecast: " + @forecast.id.to_s + ": farm:" + @forecast.farm_code + ", season: " + @forecast.season.to_s + ", rmt_variety: " + @forecast_variety_indicator.forecast_variety.rmt_variety_code + " '"%>

		<%= build_forecast_variety_indicator_track_indicator_form(@forecasts_variety_indicators_track_slms_indicator,'save_indicator','save_indicator')%>

		}, :layout => 'content'
  end

  def forecasts_variety_indicators_track_slms_indicator_variety_code_search_combo_changed
    variety_code                                                                                           = get_selected_combo_value(params)
    session[:forecasts_variety_indicators_track_slms_indicator_search_form][:variety_code_combo_selection] = variety_code
    #commodity_code = 	session[:forecasts_variety_indicators_track_slms_indicator_search_form][:commodity_code_combo_selection]
    @track_slms_indicator_codes                                                                            = TrackSlmsIndicator.find_by_sql("Select distinct track_slms_indicator_code from track_slms_indicators where variety_type = 'rmt_variety' and variety_code = '#{variety_code}'").map { |g| [g.track_slms_indicator_code] }
    @track_slms_indicator_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('forecasts_variety_indicators_track_slms_indicator','track_slms_indicator_code',@track_slms_indicator_codes)%>

		}

  end

  def save_indicator
# =============================================================================================
# saves a forecast_variety_indicator's forecasts_variety_indicators_track_slms_indicator record
# =============================================================================================
    @forecast_variety_indicator = ForecastVarietyIndicator.find(session[:forecast_variety_indicator])
    #commodity_code = params[:forecasts_variety_indicators_track_slms_indicator][:commodity_code]
    variety_code                = params[:forecasts_variety_indicators_track_slms_indicator][:rmt_variety_code]
    track_slms_indicator_code   = params[:forecasts_variety_indicators_track_slms_indicator][:track_slms_indicator_code]
    @track_slms_indicator       = TrackSlmsIndicator.find(:first, :conditions =>[' variety_code = ? and track_slms_indicator_code = ? ', variety_code, track_slms_indicator_code])

    if @track_slms_indicator != nil && !@forecast_variety_indicator.has_forecast_variety_indicators_track_slms_indicator(@track_slms_indicator)
      if (@forecast_variety_indicator.add_track_slms_indicator(@track_slms_indicator))
        flash[:notice] = "forecasts_variety_indicators_track_slms_indicator record saved"
      else
        flash[:error] = "Sorry, track indicator is invalid"
      end
#    forecasts_variety_indicators_track_slms_indicator = ForecastVarietyIndicatorsTrackSlmsIndicator.new
#    forecasts_variety_indicators_track_slms_indicator.track_slms_indicator_id = @track_slms_indicator.id
#    forecasts_variety_indicators_track_slms_indicator.forecast_variety_indicator_id = @forecast_variety_indicator.id
#
#
#       if forecasts_variety_indicators_track_slms_indicator.save
#        flash[:notice] = "forecasts_variety_indicators_track_slms_indicator record saved"
#      else
#        flash[:notice] = "forecasts_variety_indicators_track_slms_indicator could not be saved :::::" +  forecasts_variety_indicators_track_slms_indicator.forecast_variety_indicator_id.to_s
#      end
    else
      flash[:error] = "forecast_variety_indicator already has this track_slms_indicator"
    end
# ===============================================
    return_to_forecast_edit_header

  end

  def edit_forecast_variety_indicator
    @forecast_variety_indicator          = ForecastVarietyIndicator.find(params[:id])
    @forecast_variety                    = @forecast_variety_indicator.forecast_variety
    session[:forecast_variety]           = @forecast_variety
    session[:forecast_variety_indicator] = @forecast_variety_indicator.id

    render :inline => %{
		<% @content_header_caption = "'edit forecast variety indicator record for forecast variety: " + @forecast_variety.rmt_variety_code + " '"%>

		<%= build_forecast_variety_indicator_form(@forecast_variety_indicator,'update_forecast_variety_indicator','update_forecast_variety_indicator')%>

		}, :layout => 'content'
  end

  def update_forecast_variety_indicator
    @forecast_variety_indicator = ForecastVarietyIndicator.find(session[:forecast_variety_indicator])
    @forecast_variety           = ForecastVariety.find(session[:forecast_variety])
    quantity                    = calculate_quantity_sum(@forecast_variety)

    quantity                    = quantity - @forecast_variety_indicator.quantity + params[:forecast_variety_indicator][:quantity].to_i

    if quantity > @forecast_variety.quantity
#------------ VALIDATION RULE ---------------?????????????????????????????
      flash[:error] = 'quantities of indicators bigger than total entered ::::::: ' + quantity.to_s + " > " + @forecast_variety.quantity.to_s
      return_to_forecast_edit_header
    else
      if quantity == @forecast_variety.quantity
        @forecast_variety.status_code = "balanced"
      else
        @forecast_variety.status_code = "unbalanced"
      end

      @forecast_variety_indicator.forecast_variety_id    = @forecast_variety.id
#      @forecast_variety_indicator.number_tickets_printed = 0

      if  @forecast_variety.update_attributes(@forecast_variety.attributes)
        if @forecast_variety_indicator.update_attributes(params[:forecast_variety_indicator])

          flash[:notice] = 'forecast_variety_indicator record updated successfully'
          return_to_forecast_edit_header

        else

          flash[:error] = 'forecast_variety_indicator record could not be updated'

          render :inline => %{
		<% @content_header_caption = "'update forecast variety indicator record for forecast variety: " + @forecast_variety.rmt_variety_code + " '"%>

		<%= build_forecast_variety_indicator_form(@forecast_variety_indicator,'save_forecast_variety_indicator','save_forecast_variety_indicator')%>

		}, :layout => 'content'
        end
      else
        flash[:error] = 'forecast_variety record could not be updated'
        return_to_forecast_edit_header
      end
    end
  end

  def delete_forecast_variety_indicator
    @forecast_variety_indicator = ForecastVarietyIndicator.find(params[:id])
    @forecast_variety           = @forecast_variety_indicator.forecast_variety

    if @forecast_variety_indicator.destroy
      flash[:notice]                = 'forecast_variety_indicator has been deleted'
      @forecast_variety.status_code = "unbalanced"
      @forecast_variety.update_attributes(@forecast_variety.attributes)
    else
      flash[:error] = 'forecast_variety_indicator could NOT be deleted'
    end

    return_to_forecast_edit_header
  end

  def list_forecast_variety_indicators_track_slms_indicators
    @id                                                 = params[:id]
    @forecasts_variety_indicators_track_slms_indicators = ForecastVarietyIndicatorsTrackSlmsIndicator.find_all_by_forecast_variety_indicator_id(@id)

    render :inline => %{
                        <% @content_header_caption = "'list of track_slms_indicators for forecast_variety_indicator: " + @id.to_s  + " '"%>
                        <table border="1" style="border-collapse: collapse;">
                          <tr>
                            <td style="background-color: lightgray;">
                               <label>track slms indicators</label>
                            </td>
                          </tr>

                        <% for forecast_variety_indicators_track_slms_indicator in @forecasts_variety_indicators_track_slms_indicators %>
                          <tr>
                           <td>
                                  <%= forecast_variety_indicators_track_slms_indicator.track_slms_indicator.track_slms_indicator_code %><br>
                           </td>
                          </tr>
                        <% end %>

                        </table>
                        }, :layout => 'content'

  end

  def clone_forecast
    session[:forecast_id] = params[:id]
    @action  = 'clone_forecast_submit'
    @caption = 'clone_forecast'
    render :inline => %{
		<% @content_header_caption = "'clone forecast'"%>

		<%= build_clone_forecast_form(@forecast,@action,@caption)%>

		}, :layout => 'content'
    
#    session[:forecast_id] = params[:id]
#    render :inline=> %{
#                      <script>
#                     var season_code = prompt("Enter season_code: ");
#                     if(season_code == null) {
#                      window.location.href = "/rmt_processing/forecast/render_list_forecasts";
#                     } else if(season_code.trim() == "") {
#                      window.location.href = "/rmt_processing/forecast/render_list_forecasts";
#                     } else {
#                      window.location.href = "/rmt_processing/forecast/clone_forecast_submit/" + season_code;
#                     }
#                     </script>
#                  }
  end

  def clone_forecast_submit
    @original_forecast_header = Forecast.find(session[:forecast_id])
    @forecast_header_copy  = @original_forecast_header.clone
    @forecast_header_copy.forecast_type_code = params[:forecast][:forecast_type_code]
    @forecast_header_copy.season = params[:forecast][:season]
    @forecast_header_copy.tickets_printed_datetime = nil

    begin
      do_cloning('active','clone')
#      params[:id] = @forecast_header_copy.id
#      edit_forecast
      render :inline => %{
              <script>
                window.opener.frames[1].location.href = "/rmt_processing/forecast/edit_forecast/<%= @forecast_header_copy.id %>";
                window.close();
              </script>
      }, :layout => 'content'
    rescue
      raise $!
      flash[:error] = 'Forecast could not be cloned : ' + $!.to_s
#      list_forecasts
      render :inline => %{
              <script>
                window.opener.frames[1].location.href = "/rmt_processing/forecast/list_forecasts";
                window.close();
              </script>
      }, :layout => 'content'
    end
  end

  def do_cloning(forecast_status_code, mode=nil)
#  ----------------------------------------------------
#  changing statuses of both records
#  ----------------------------------------------------
    @forecast_header_copy.forecast_status_code = forecast_status_code
    @forecast_header_copy.sequence_number      = generate_sequence_number(@forecast_header_copy) + 1
    @forecast_header_copy.previous_forecast_id = @original_forecast_header.id
#   ========================
#   generating forecast_code
#   ========================
    @forecast_header_copy.forecast_code        = @forecast_header_copy.forecast_type_code + "_" + @forecast_header_copy.season.to_s + "_" + @forecast_header_copy.farm_code + "_" + @forecast_header_copy.sequence_number.to_s
#   ========================
    @forecast_header_copy.forecast_status      = ForecastStatus.find_by_forecast_status_code(forecast_status_code)
#  ----------------------------------------------------

    ActiveRecord::Base.transaction do
      @forecast_header_copy.save!
      #  ----------------------------------------------------
      #  making a copy of all forecasts_track_slms_indicators
      #  ----------------------------------------------------
      for track_slms_indicator in @original_forecast_header.track_slms_indicators
        @forecast_header_copy.add_track_slms_indicator(track_slms_indicator)
      end
      #  ----------------------------------------------------

      #  ----------------------------------------------------
      #  making a copy of all forecast_varieties
      #  ----------------------------------------------------
      for forecast_variety in @original_forecast_header.forecast_varieties
        forecast_variety_copy             = forecast_variety.clone
        forecast_variety_copy.forecast_id = @forecast_header_copy.id
        @forecast_header_copy.forecast_varieties.push(forecast_variety_copy)

        #  ----------------------------------------------------
        #  making a copy of all forecast_variety_indicators
        #  ----------------------------------------------------
        for forecast_variety_indicator in forecast_variety.forecast_variety_indicators
          forecast_variety_indicator_copy                     = forecast_variety_indicator.clone
          forecast_variety_indicator_copy.forecast_variety_id = forecast_variety_copy.id
          forecast_variety_indicator_copy.number_tickets_printed = 0 if(mode && mode=="clone") #mode = {"clone","revision"}
          forecast_variety_copy.forecast_variety_indicators.push(forecast_variety_indicator_copy)

          #  ----------------------------------------------------
          #  making a copy of all forecast_variety_indicators_track_slms_indicators
          #  ----------------------------------------------------
          for forecast_variety_indicators_track_slms_indicator in forecast_variety_indicator.forecast_variety_indicators_track_slms_indicators
            forecast_variety_indicators_track_slms_indicator_copy = forecast_variety_indicators_track_slms_indicator.clone            
            forecast_variety_indicator_copy.forecast_variety_indicators_track_slms_indicators.push(forecast_variety_indicators_track_slms_indicator_copy)
          end
          #  ----------------------------------------------------

        end
        #  ----------------------------------------------------

      end
      #  ----------------------------------------------------
    end
  end

  def revise_forecast

    @original_forecast_header                  = Forecast.find(params[:id]) #Must be updated at the end = because of the status change
    if @original_forecast_header.forecast_status_code == "revised"
      flash[:notice] = 'record has already been revised '
      edit_forecast
      return
    end

    @forecast_header_copy                      = @original_forecast_header.clone
    
    begin
      do_cloning('current')
      @original_forecast_header.forecast_status_code = "revised"
      @original_forecast_header.forecast_status      = ForecastStatus.find_by_forecast_status_code("revised")
      @original_forecast_header.update

      params[:id] = @forecast_header_copy.id
      edit_forecast
    rescue
      raise $!
      flash[:error] = 'Forecast could not be revised : ' + $!.to_s
      list_forecasts
    end
  end

  def stop_active_bin_ticket_print_job
    stop_active_print_job(Globals.bin_ticket_printing_ip,Globals.get_label_printing_server_port,Globals.bin_ticket_printer_name)
  end

  def print_bin_tickets_commit
    @id = params['hash_object']['id']
    @qty_to_print = params['hash_object']['qty']
    @printer = params['hash_object']['printer']

    if(params['hash_object']['qty'].to_s.empty?)
      flash[:error] = "You must provide a quantity to print"
      params['id'] = @id
      params['qty'] = @qty_to_print
      print_screen
      return
    elsif(params['hash_object']['printer'].to_s.empty?)
      flash[:error] = "You must select a valid printer"
      params['id'] = @id
      params['qty'] = @qty_to_print
      print_screen
      return
    end

    if(printer_forecast_variety_indicator = ForecastVarietyIndicator.find_by_active_printer(@printer))
      @msg = "The printer you selected is being used to print tickets for #{printer_forecast_variety_indicator.forecast_variety.forecast.forecast_code},variety:#{printer_forecast_variety_indicator.forecast_variety.rmt_variety_code},indicator: #{printer_forecast_variety_indicator.track_slms_indicator_code}. Do you want to continue anyway?"
      render :inline => %{
       <script>
         if (confirm("<%=@msg%>") == true){
            window.location.href = "/rmt_processing/forecast/print_bin_tickets_execute?id=#{@id}&qty=#{@qty_to_print}&printer=#{@printer}";
         }else{
            window.location.href = "/rmt_processing/forecast/cancel_bin_tickets_printing?id=#{@id}&qty=#{@qty_to_print}&printer=#{@printer}";
         }
      </script>
        }
      return
    end

    params['id'] = @id
    params['qty'] = @qty_to_print
    params['printer'] = @printer
    print_bin_tickets_execute
  end

  def cancel_bin_tickets_printing
    inactive_printer_fvi = ActiveRecord::Base.connection.select_all("
    ((select * FROM (VALUES ('#{Globals.bin_ticket_printer_names.join("'),('")}')) A(active_printer))
                              except
    (select active_printer from forecast_variety_indicators where active_printer is not null))")
    params['printer'] = (inactive_printer_fvi.length > 0 ? inactive_printer_fvi[0]['active_printer'] : nil)
    print_screen
  end

  def print_bin_tickets_execute
    begin
      Carton.transaction do

        if !RUBY_PLATFORM.index('linux')
          file_name = session[:user_id].user_name + "_BIN_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".bat"
          file = File.new(file_name, "w")
          file.puts "ruby \"app\\models\\bin_ticket_printing.rb\"" + " BATCH " + params['id'].to_s + " " + params['qty'] + " " + params['printer']
          file.close
          @result = eval "\`" + "\"" + file_name + "\"" + "\"`"
        else
          file_name = session[:user_id].user_name + "_BIN_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".sh"
          file = File.new(file_name, "w")
          # file.puts "ruby \"app/models/bin_ticket_printing.rb\"" + " BATCH " + params['id'].to_s + " " + params['qty'] + " " + params['printer']
          file.puts "/usr/local/bin/ruby \"app/models/bin_ticket_printing.rb\"" + " BATCH " + params['id'].to_s + " " + params['qty'] + " " + params['printer']
          file.close
          @result = eval "\` sh " + file_name + "\`"

        end

        File.delete(file_name)

        if @result.index("error")
          raise @result
        end
        @forecast_variety_indicators = ForecastVarietyIndicator.find_by_sql("
                                        select *
                                        from forecast_variety_indicators
                                          join forecast_varieties on forecast_varieties.id=forecast_variety_indicators.forecast_variety_id
                                              join forecasts on forecasts.id=forecast_varieties.forecast_id
                                        where forecasts.id=#{session[:forecast_id]} ")
        @forecast_variety_indicators.each do |fvi|
          if (fvi.number_tickets_printed && fvi.number_tickets_printed > 0)
            Forecast.update(session[:forecast_id], {:tickets_printed_datetime => Time.now})
            break
          end
        end
        @freeze_flash = true

        ActiveRecord::Base.connection.execute("update forecast_variety_indicators set active_printer=null where active_printer='#{params['printer']}';
                                          update forecast_variety_indicators set active_printer='#{params['printer']}' where id=#{params['id']};")

        render :inline => %{
                <script>
                      window.opener.location.href = "/rmt_processing/forecast/active_forecast";
                      window.close();
                </script>
          }, :layout => 'content'
      end

    rescue
      handle_error("Bin Tickets could not be printed")
    end
  end

  def job_completed
    ActiveRecord::Base.connection.execute("update forecast_variety_indicators set active_printer=null where id=#{params['id']};")
    active_forecast
  end

  def cancel_print_job
    @forecast_variety_indicator = ForecastVarietyIndicator.find(params[:id].to_i)
    ActiveRecord::Base.connection.execute("update forecast_variety_indicators set active_printer=null where id=#{params['id']};")
    flash[:notice] = stop_active_print_job(Globals.bin_ticket_printing_ip,Globals.get_label_printing_server_port,@forecast_variety_indicator.active_printer).body
    active_forecast
  end

  def print_screen
    @object_builder = ObjectBuilder.new
    @hash_object = @object_builder.build_hash_object({:id=>params['id'], :qty=>params['qty'], :printer=>params['printer']})
    @forecast_variety_indicator = ForecastVarietyIndicator.find(params[:id].to_i)
    @content_header_caption = "'print bin tickets for commodity(#{@forecast_variety_indicator.forecast_variety.commodity_code}), rmt_variety(#{@forecast_variety_indicator.forecast_variety.rmt_variety_code}),  indicator(#{@forecast_variety_indicator.track_slms_indicator_code})'"
    render :inline => %{
      <%= build_print_screen_form(@hash_object)%>
    }, :layout => 'content'
  end

  def print_bin_tickets
    @forecast_variety_indicator = ForecastVarietyIndicator.find(params[:id].to_i)

    render :inline => %{
  	   <% @url = "http://" + request.host_with_port + "/" + "rmt_processing/forecast/print_screen?id=#{@forecast_variety_indicator.id}&qty=#{@forecast_variety_indicator.quantity}" %>
  	   <script>
          another_window = window.open("<%=@url%>", "","width=600,height=280,top=200,left=200,toolbar=no,menubar=no,status=yes,scrollbars=yes,resizable=no" );
          window.location.href = "/rmt_processing/forecast/edit_forecast/<%= @forecast_variety_indicator.forecast_variety.forecast.id %>"
       </script>

  	 }, :layout => "content"

  end

#=======================================================
# End Bin Tickets Printing By Happymore
#=======================================================

  def print_forecast_report
    render :inline=> %{TO DO: 1. Get report params from Gerrit<br>2. Implement automatic jasper printing <br>3. Implement functionality}, :layout=>'content'
#    <tr>
#         <td>
#         <!--Forecast columns names table-->
#           <table>
#
#               <tr>
#                 <td style='padding-top: 15px;'>
#                   <label>forecast report</label>
#                 </td>
#                 <td >
#                    <% params_hash =  { "report_type" => "Forecast","report_user_ref"=>"Printed_from_Luks_Rails_server","printer_name" => "Primo","show_report"=>"yes", "reference_id" => 1, "reference_type" => "forecasts","paraSeason" => @forecast.season,"paraFarm_code" => @forecast.farm_code }  %>
#                    <%= link_to(image_tag("/images/view.png", :border => 0),generate_report_parameters(params_hash),:popup => true) %>
#                 </td>
#               </tr>
#           </table>
#         <!--end of Forecast columns values table-->
#         </td>
#       </tr>
  end

  def active_forecast
    if (session[:forecast_id])
      @forecast              = Forecast.find(session[:forecast_id])
      @track_slms_indicators = @forecast.track_slms_indicators
      params[:id]            = session[:forecast_id]
      edit_forecast
    else
      flash[:notice] = "no active forecast"
      render :inline=>%{}, :layout=>'content'
    end
  end
end
