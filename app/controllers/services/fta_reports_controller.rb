class Services::FtaReportsController < ApplicationController
  def program_name?
    'fta_reports'
  end

  def bypass_generic_security?
    true
  end

  def fta_reports_index
    render :template=>'/services/fta_reports/index',:layout=>'content'
  end

#=======================
#======== START ========
#== FTA Report Links ===
#=======================
  def view_last_fta_report
    @fta_instrument = InstrumentsFtaSession.find(:first,:order => 'id DESC')
    params[:id] = @fta_instrument.id
    view_fta_report
  end

  def view_fta_report
    @fta_instrument = InstrumentsFtaSession.find(params[:id])

    report_unit ="reportUnit=/RMT/FTA&"
    report_parameters="output=pdf&session_id=#{@fta_instrument.id}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)

  end

  def search_fta_reports
    dm_session[:parameter_fields_values] = nil
    dm_session['se_layout']              = 'content'
    @content_header_caption           = "'search search fta reports'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form("search_fta_reports.yml", "submit_search_fta_reports_search")
  end

  def submit_search_fta_reports_search
    session[:query] = "@instruments_fta_session_pages = Paginator.new self, InstrumentsFtaSession.count, @@page_size,@current_page
                       @instruments_fta_sessions = InstrumentsFtaSession.find_by_sql(dm_session[:search_engine_query_definition])"
    @instruments_fta_sessions = eval(session[:query]) if(!@instruments_fta_sessions)#ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    if (@instruments_fta_sessions.length > 0)
      render_found_fta_reports
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                              window.close();
                            </script>
                          }, :layout => 'content'
    end
  end

  def render_found_fta_reports
    @content_header_caption           = "''"
    render :inline => %{
        <% grid = build_fta_reports_grid(@instruments_fta_sessions)%>
        <% grid.caption    = 'stock_locations_histories' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end

#=======================
#======== START ========
#== RFM Report Links ===
#=======================

  def view_last_rfm_report
    @rfm_instrument = InstrumentsRfmSession.find(:first,:order => 'id DESC')
    params[:id] = @rfm_instrument.id
    view_rfm_report
  end

  def view_rfm_report
    @rfm_instrument = InstrumentsRfmSession.find(params[:id])

    report_unit ="reportUnit=/RMT/RFM&"
    report_parameters="output=pdf&session_id=#{@rfm_instrument.id}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)

  end

  def search_rfm_reports
    dm_session[:parameter_fields_values] = nil
    dm_session['se_layout']              = 'content'
    @content_header_caption           = "'search search rfm reports'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form("search_rfm_reports.yml", "submit_search_rfm_reports_search")
  end

  def submit_search_rfm_reports_search
    session[:query] = "@instruments_rfm_session_pages = Paginator.new self, InstrumentsRfmSession.count, @@page_size,@current_page
                       @instruments_rfm_sessions = InstrumentsRfmSession.find_by_sql(dm_session[:search_engine_query_definition])"
    @instruments_rfm_sessions = eval(session[:query]) if(!@instruments_rfm_sessions)#ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    if (@instruments_rfm_sessions.length > 0)
      render_found_rfm_reports
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                              window.close();
                            </script>
                          }, :layout => 'content'
    end
  end

  def render_found_rfm_reports
    @content_header_caption           = "''"
    render :inline => %{
        <% grid = build_rfm_reports_grid(@instruments_rfm_sessions)%>
        <% grid.caption    = 'stock_locations_histories' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end
end
