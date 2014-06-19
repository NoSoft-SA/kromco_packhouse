class  RawMaterials::CalendarController < ApplicationController
 
def program_name?
	"calendar"
end

def bypass_generic_security?
	true
end

def list_iso_weeks
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:iso_weeks_page] = params['page']

		 render_list_iso_weeks

		 return 
	else
		session[:iso_weeks_page] = nil
	end

	list_query = "@iso_week_pages = Paginator.new self, IsoWeek.count, @@page_size,@current_page
	 @iso_weeks = IsoWeek.find(:all,
				 :limit => @iso_week_pages.items_per_page,
				 :offset => @iso_week_pages.current.offset)"
	session[:query] = list_query
	render_list_iso_weeks
end


def render_list_iso_weeks
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:iso_weeks_page] if session[:iso_weeks_page]
	@current_page = params['page'] if params['page']
	@iso_weeks =  eval(session[:query]) if !@iso_weeks
	render :inline => %{
      <% grid            = build_iso_week_grid(@iso_weeks,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all iso_weeks' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@iso_week_pages) if @iso_week_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_iso_weeks_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_iso_week_search_form
end

def render_iso_week_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  iso_weeks'"%> 

		<%= build_iso_week_search_form(nil,'submit_iso_weeks_search','submit_iso_weeks_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_iso_weeks_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_iso_week_search_form(true)
end

def render_iso_week_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  iso_weeks'"%> 

		<%= build_iso_week_search_form(nil,'submit_iso_weeks_search','submit_iso_weeks_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_iso_weeks_search
	if params['page']
		session[:iso_weeks_page] =params['page']
	else
		session[:iso_weeks_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @iso_weeks = dynamic_search(params[:iso_week] ,'iso_weeks','IsoWeek')
	else
		@iso_weeks = eval(session[:query])
	end
	if @iso_weeks.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_iso_week_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_iso_weeks
		end

	else

		render_list_iso_weeks
	end
end

 
def delete_iso_week
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:iso_weeks_page] = params['page']
		render_list_iso_weeks
		return
	end
	id = params[:id]
	if id && iso_week = IsoWeek.find(id)
		iso_week.destroy
		session[:alert] = " Record deleted."
		render_list_iso_weeks
	end
  rescue
    handle_error("iso_week could not be deleted")
  end
end
 
def new_iso_week
	return if authorise_for_web(program_name?,'create')== false
		render_new_iso_week
end
 
def create_iso_week
  begin
	 @iso_week = IsoWeek.new(params[:iso_week])
	 if @iso_week.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_iso_week
	 end
  rescue
    handle_error("iso_week could not be created")
  end
end

def render_new_iso_week
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new iso_week'"%> 

		<%= build_iso_week_form(@iso_week,'create_iso_week','create_iso_week',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_iso_week
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @iso_week = IsoWeek.find(id)
		render_edit_iso_week

	 end
end


def render_edit_iso_week
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit iso_week'"%> 

		<%= build_iso_week_form(@iso_week,'update_iso_week','update_iso_week',true)%>

		}, :layout => 'content'
end
 
def update_iso_week
  begin
	if params[:page]
		session[:iso_weeks_page] = params['page']
		render_list_iso_weeks
		return
	end

		@current_page = session[:iso_weeks_page]
	 id = params[:iso_week][:id]
	 if id && @iso_week = IsoWeek.find(id)
		 if @iso_week.update_attributes(params[:iso_week])
			@iso_weeks = eval(session[:query])
			render_list_iso_weeks
	 else
			 render_edit_iso_week

		 end
	 end
   rescue
    handle_error("iso_week could not be updated")
  end
 end

#===================
#SEASON CODE
#===================
def list_seasons
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:seasons_page] = params['page']

		 render_list_seasons

		 return 
	else
		session[:seasons_page] = nil
	end

	list_query = "@season_pages = Paginator.new self, Season.count, @@page_size,@current_page
	 @seasons = Season.find(:all,
				 :limit => @season_pages.items_per_page,
				 :offset => @season_pages.current.offset)"
	session[:query] = list_query
	render_list_seasons
end


def render_list_seasons
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:seasons_page] if session[:seasons_page]
	@current_page = params['page'] if params['page']
	@seasons =  eval(session[:query]) if !@seasons
	render :inline => %{
      <% grid            = build_season_grid(@seasons,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all seasons' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@season_pages) if @season_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_seasons_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_season_search_form
end

def render_season_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  seasons'"%> 

		<%= build_season_search_form(nil,'submit_seasons_search','submit_seasons_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_seasons_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_season_search_form(true)
end

def render_season_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  seasons'"%> 

		<%= build_season_search_form(nil,'submit_seasons_search','submit_seasons_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_seasons_search
	if params['page']
		session[:seasons_page] =params['page']
	else
		session[:seasons_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @seasons = dynamic_search(params[:season] ,'seasons','Season')
	else
		@seasons = eval(session[:query])
	end
	if @seasons.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_season_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_seasons
		end

	else

		render_list_seasons
	end
end

 
def delete_season
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:seasons_page] = params['page']
		render_list_seasons
		return
	end
	id = params[:id]
	if id && season = Season.find(id)
		season.destroy
		session[:alert] = " Record deleted."
		render_list_seasons
	end
   rescue
    handle_error("season could not be deleted")
  end
end
 
def new_season
	return if authorise_for_web(program_name?,'create')== false
		render_new_season
end
 
def create_season
  begin
	 @season = Season.new(params[:season])
	 if @season.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_season
	 end
  rescue
    handle_error("season could not be created")
  end
end

def render_new_season
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new season'"%> 

		<%= build_season_form(@season,'create_season','create_season',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_season
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @season = Season.find(id)
		render_edit_season

	 end
end


def render_edit_season
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit season'"%> 

		<%= build_season_form(@season,'update_season','update_season',true)%>

		}, :layout => 'content'
end
 
def update_season
  begin
	if params[:page]
		session[:seasons_page] = params['page']
		render_list_seasons
		return
	end

		@current_page = session[:seasons_page]
	 id = params[:season][:id]
	 if id && @season = Season.find(id)
		 if @season.update_attributes(params[:season])
			@seasons = eval(session[:query])
			render_list_seasons
	 else
			 render_edit_season

		 end
	 end
   rescue
    handle_error("season could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: commodity_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(seasons)
#	-----------------------------------------------------------------------------------------------------------
def season_season_code_search_combo_changed
	season_code = get_selected_combo_value(params)
	session[:season_search_form][:season_code_combo_selection] = season_code
	@commodity_codes = Season.find_by_sql("Select distinct commodity_code from seasons where season_code = '#{season_code}'").map{|g|[g.commodity_code]}
	@commodity_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('season','commodity_code',@commodity_codes)%>

		}

end



end
