class  RmtProcessing::PresortGrowerGradingFarmController < ApplicationController

  def program_name?
    "presort_grower_grading"
  end

  def bypass_generic_security?
    true
  end

  def list_presort_grower_grading_farms
    if params[:id]
      query="select * from pool_graded_ps_farms where pool_graded_ps_summary_id=#{params[:id]}"
      session[:query]="ActiveRecord::Base.connection.select_all(\"#{query}\")"
      @pool_graded_ps_farms=ActiveRecord::Base.connection.select_all(query)
    else
      @pool_graded_ps_farms=session[:pool_graded_ps_summary][1]
    end
    render_list_presort_grower_grading_farms_grid
  end

  def render_list_presort_grower_grading_farms_grid
    @pagination_server = ""
    @current_page = session[:presort_grower_grading_page]
    @current_page = params['page']||= session[:presort_grower_grading_page]
    render :inline => %{
		<% grid = build_presort_grower_grading_farms_grid(@pool_graded_ps_farms)%>
		<% grid.caption = 'Farms'%>
    <%grid.height='200'%>
		<% @header_content = grid.build_grid_data %>
		<% @pagination = pagination_links(@presort_grower_grading_pages) if @presort_grower_grading_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
  end

end