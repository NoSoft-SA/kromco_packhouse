class Fg::RecoolingController < ApplicationController
  def program_name?
     "recooling"
  end

  def bypass_generic_security?
    true
  end

  def find_jobs
     return if authorise_for_web(program_name?, 'recooling') == false

      dm_session['se_layout'] = 'content'
      @content_header_caption = "'find_jobs'"
      build_remote_search_engine_form("search_jobs.yml", "submit_jobs_search")
      dm_session[:redirect] = true
  end

  def submit_jobs_search
   @jobs = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])

    render :inline => %{
      <% grid            = build_jobs_grid(@jobs) %>
      <% grid.caption    = 'jobs' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  def view_reports
    job_id = params[:id]
        report_unit ="reportUnit=/FG/recooling_job&"
    report_parameters="output=pdf&job_id=" +"#{job_id}" 
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password +  report_parameters)

  end



end
