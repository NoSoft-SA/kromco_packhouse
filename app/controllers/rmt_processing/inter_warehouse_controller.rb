class RmtProcessing::InterWarehouseController < ApplicationController


  def program_name?
    "inter_warehouse"
  end

  def bypass_generic_security?
    true
  end

  def list_tripsheets
    @vehicle_jobs = VehicleJob.find_by_sql("select vehicle_jobs.*,vehicle_job_types.vehicle_job_type_code
                                            from vehicle_jobs
                                            inner join vehicle_job_types on vehicle_jobs.vehicle_job_types_id = vehicle_job_types.id
                                            where vehicle_job_types.vehicle_job_type_code = 'BINS'
                                            order by date_time_loaded desc limit 100")

    render :inline => %{
      <% grid            = build_vehicle_jobs_grid(@vehicle_jobs,@can_edit,@can_delete) %>
      <% grid.caption    = 'vehicle jobs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@vehicle_jobs_pages) if @vehicle_jobs_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

    def print_tripsheet

    vehicle_job_id = params[:id]
    report_unit ="reportUnit=/reports/MES/RMT/vehicle_job&"
    report_parameters="output=pdf&vehicle_job_id=" +"#{vehicle_job_id}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)
  end






end
