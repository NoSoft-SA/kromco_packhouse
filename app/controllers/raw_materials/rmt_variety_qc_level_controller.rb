class  RawMaterials::RmtVarietyQcLevelController < ApplicationController
 
def program_name?
	"rmt_variety_qc_level"
end

def bypass_generic_security?
	true
end
def list_rmt_variety_qc_levels
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:rmt_variety_qc_levels_page] = params['page']

		 render_list_rmt_variety_qc_levels

		 return 
	else
		session[:rmt_variety_qc_levels_page] = nil
	end

	list_query = "@rmt_variety_qc_level_pages = Paginator.new self, RmtVarietyQcLevel.count, @@page_size,@current_page
	 @rmt_variety_qc_levels = RmtVarietyQcLevel.find(:all,
				 :limit => @rmt_variety_qc_level_pages.items_per_page,
				 :offset => @rmt_variety_qc_level_pages.current.offset)"
	session[:query] = list_query
	render_list_rmt_variety_qc_levels
end


def render_list_rmt_variety_qc_levels
	@pagination_server = "list_rmt_variety_qc_levels"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:rmt_variety_qc_levels_page]
	@current_page = params['page']||= session[:rmt_variety_qc_levels_page]
	@rmt_variety_qc_levels =  eval(session[:query]) if !@rmt_variety_qc_levels
	render :inline => %{
		<% grid = build_rmt_variety_qc_level_grid(@rmt_variety_qc_levels,@can_edit,@can_delete)%>
		<% grid.caption = 'list of all rmt_variety_qc_levels'%>
		<% @header_content = grid.build_grid_data %>

		<% @pagination = pagination_links(@rmt_variety_qc_level_pages) if @rmt_variety_qc_level_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_rmt_variety_qc_levels_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_rmt_variety_qc_level_search_form
end

def render_rmt_variety_qc_level_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rmt_variety_qc_levels'"%> 

		<%= build_rmt_variety_qc_level_search_form(nil,'submit_rmt_variety_qc_levels_search','submit_rmt_variety_qc_levels_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_rmt_variety_qc_levels_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_rmt_variety_qc_level_search_form(true)
end

 
def submit_rmt_variety_qc_levels_search
	@rmt_variety_qc_levels = dynamic_search(params[:rmt_variety_qc_level] ,'rmt_variety_qc_levels','RmtVarietyQcLevel')
	if @rmt_variety_qc_levels.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_rmt_variety_qc_level_search_form
		else
			render_list_rmt_variety_qc_levels
	end
end

 
def delete_rmt_variety_qc_level
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:rmt_variety_qc_levels_page] = params['page']
		render_list_rmt_variety_qc_levels
		return
	end
	id = params[:id]
	if id && rmt_variety_qc_level = RmtVarietyQcLevel.find(id)
		rmt_variety_qc_level.destroy
		session[:alert] = ' Record deleted.'
		render_list_rmt_variety_qc_levels
	end
	rescue
		handle_error('record could not be deleted')
end
end
 
def new_rmt_variety_qc_level
	return if authorise_for_web(program_name?,'create')== false
		render_new_rmt_variety_qc_level
end
 
def create_rmt_variety_qc_level
 begin
	 @rmt_variety_qc_level = RmtVarietyQcLevel.new(params[:rmt_variety_qc_level])
	 if @rmt_variety_qc_level.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_rmt_variety_qc_level
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_rmt_variety_qc_level
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new rmt_variety_qc_level'"%> 

		<%= build_rmt_variety_qc_level_form(@rmt_variety_qc_level,'create_rmt_variety_qc_level','create_rmt_variety_qc_level',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_rmt_variety_qc_level
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @rmt_variety_qc_level = RmtVarietyQcLevel.find(id)
		render_edit_rmt_variety_qc_level

	 end
end


def render_edit_rmt_variety_qc_level
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit rmt_variety_qc_level'"%> 

		<%= build_rmt_variety_qc_level_form(@rmt_variety_qc_level,'update_rmt_variety_qc_level','update_rmt_variety_qc_level',true)%>

		}, :layout => 'content'
end
 
def update_rmt_variety_qc_level
 begin

	 id = params[:rmt_variety_qc_level][:id]
	 if id && @rmt_variety_qc_level = RmtVarietyQcLevel.find(id)
		 if @rmt_variety_qc_level.update_attributes(params[:rmt_variety_qc_level])
			@rmt_variety_qc_levels = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_rmt_variety_qc_levels
	 else
			 render_edit_rmt_variety_qc_level

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
  def search_dm_rmt_variety_qc_levels
    return if authorise_for_web(program_name?,'read')== false
    dm_session['se_layout']              = 'content'
    @content_header_caption              = "'Search Rmt variety qc levels'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form('search_rmt_variety_qc_levels.yml', 'search_dm_rmt_variety_qc_levels_grid')
  end

 
  def search_dm_rmt_variety_qc_levels_grid
    @rmt_variety_qc_levels = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @can_edit        = authorise(program_name?, 'edit', session[:user_id])
    @can_delete      = authorise(program_name?, 'delete', session[:user_id])
    @stat            = dm_session[:search_engine_query_definition]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]

    render :inline => %{
      <% grid            = build_rmt_variety_qc_level_dm_grid(@rmt_variety_qc_levels, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
      <% grid.caption    = 'Rmt variety qc levels' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end

 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: season_id
#	---------------------------------------------------------------------------------
def rmt_variety_qc_level_season_code_changed
	season_code = get_selected_combo_value(params)
	session[:rmt_variety_qc_level_form][:season_code_combo_selection] = season_code
	@ids = RmtVarietyQcLevel.ids_for_season_code(season_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_variety_qc_level','id',@ids)%>

		}

end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: rmt_variety_id
#	---------------------------------------------------------------------------------
def rmt_variety_qc_level_commodity_code_changed
	commodity_code = get_selected_combo_value(params)
	session[:rmt_variety_qc_level_form][:commodity_code_combo_selection] = commodity_code
	@rmt_variety_codes = RmtVarietyQcLevel.rmt_variety_codes_for_commodity_code(commodity_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_variety_qc_level','rmt_variety_code',@rmt_variety_codes)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(rmt_variety_qc_levels)
#	-----------------------------------------------------------------------------------------------------------
def rmt_variety_qc_level_id_search_combo_changed
	id = get_selected_combo_value(params)
	session[:rmt_variety_qc_level_search_form][:id_combo_selection] = id
	@season_ids = RmtVarietyQcLevel.find_by_sql("Select distinct season_id from rmt_variety_qc_levels where id = '#{id}'").map{|g|[g.season_id]}
	@season_ids.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_variety_qc_level','season_id',@season_ids)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_variety_qc_level_season_id'/>
		<%= observe_field('rmt_variety_qc_level_season_id',:update => 'rmt_variety_id_cell',:url => {:action => session[:rmt_variety_qc_level_search_form][:season_id_observer][:remote_method]},:loading => "show_element('img_rmt_variety_qc_level_season_id');",:complete => session[:rmt_variety_qc_level_search_form][:season_id_observer][:on_completed_js])%>
		}

end


def rmt_variety_qc_level_season_id_search_combo_changed
	season_id = get_selected_combo_value(params)
	session[:rmt_variety_qc_level_search_form][:season_id_combo_selection] = season_id
	id = 	session[:rmt_variety_qc_level_search_form][:id_combo_selection]
	@rmt_variety_ids = RmtVarietyQcLevel.find_by_sql("Select distinct rmt_variety_id from rmt_variety_qc_levels where season_id = '#{season_id}' and id = '#{id}'").map{|g|[g.rmt_variety_id]}
	@rmt_variety_ids.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_variety_qc_level','rmt_variety_id',@rmt_variety_ids)%>

		}

end



end
