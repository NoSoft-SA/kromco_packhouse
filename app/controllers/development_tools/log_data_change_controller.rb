class  DevelopmentTools::LogDataChangeController < ApplicationController

  def program_name?
    "crud_tools"
  end

  def bypass_generic_security?
    true
  end

  def render_list_run_log_data_changes
    change = params[:id]
    log_data_change = ActiveRecord::Base.connection.select_one("select * from log_data_changes where type_of_change ='#{change}' order by id desc limit 1")
    params[:id] = log_data_change['id']
    view_log_data_change
  end

  def search_data_changes
    @content_header_caption = "'find logs'"
    dm_session['se_layout'] = 'content'
    build_remote_search_engine_form("log_data_changes.yml", "render_data_logs_grid")
    dm_session[:redirect] = true
  end

  def render_data_logs_grid
    @log_data_changes = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    render_list_log_data_changes
  end

  def list_log_data_changes
    return if authorise_for_web(program_name?,'read') == false
    store_last_grid_url

    if params[:page]!= nil
      session[:log_data_changes_page] = params['page']
      render_list_log_data_changes
      return
    else
      session[:log_data_changes_page] = nil
    end

    list_query = "@log_data_change_pages = Paginator.new self, LogDataChange.count, @@page_size,@current_page
                  @log_data_changes = LogDataChange.find(:all,
         :order  => 'created_at DESC',
         :limit  => @log_data_change_pages.items_per_page,
         :offset => @log_data_change_pages.current.offset)"
    session[:query] = list_query
    render_list_log_data_changes
  end

  def render_list_log_data_changes
    @pagination_server = "list_log_data_changes"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:log_data_changes_page]
    @current_page = params['page']||= session[:log_data_changes_page]
    @log_data_changes =  eval(session[:query]) if !@log_data_changes
    render :inline => %{
      <% grid = build_log_data_change_grid(@log_data_changes,@can_edit,@can_delete)%>
      <% grid.caption = 'List of all log_data_changes'%>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@log_data_change_pages) if @log_data_change_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    },:layout => 'content'
  end

  def new_log_data_change
    return if authorise_for_web(program_name?,'create')== false
    # store_list_as_grid_url # UNCOMMENT if this action is called directly (i.e. from a menu, not from a grid)
    @log_data_change = LogDataChange.new(:user_name => session[:user_id].user_name)
    render_new_log_data_change
  end

  def create_log_data_change
    @log_data_change       = LogDataChange.new(params[:log_data_change])
    if @log_data_change.save
      render :inline=>%{ <%= close_popup_window( "New data change log created.", :reload => true ) %> }, :layout => 'content'
    else
      @is_create_retry = true
      render_new_log_data_change
    end
  rescue
    handle_error('record could not be created')
  end

  def render_new_log_data_change
    #   render (inline) the edit template
    render :inline => %{
      <% @content_header_caption = "'create new log_data_change'"%>

      <%= build_log_data_change_form(@log_data_change,'create_log_data_change','create_log_data_change',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def edit_log_data_change
    return if authorise_for_web(program_name?,'edit')==false
    id = params[:id]
    if id && @log_data_change = LogDataChange.find(id)
      render_edit_log_data_change
    end
  end

  def render_edit_log_data_change
    #   render (inline) the edit template
    render :inline => %{
      <% @content_header_caption = "'edit log_data_change'"%>

      <%= build_log_data_change_form(@log_data_change,'update_log_data_change','update_log_data_change',true)%>

    }, :layout => 'content'
  end

#   def view_log_data_change
#     @log_data_change = LogDataChange.find(params[:id])
#     render :inline => %{
#       <% @content_header_caption = "view log_data_change"%>
#
#       <h2><%= @log_data_change.type_of_change %><h2>
#
#       <table class="thinbordertable">
#       <tbody>
#       <tr><th>Ref:</th><td><%= @log_data_change.ref_nos %><hd></tr>
#       <tr><th>Created:</th><td><%= @log_data_change.created_at %><hd></tr>
#       <tr><th>By:</th><td><%= @log_data_change.user_name %><hd></tr>
#       </tbody>
#       </table>
#       <h3>Notes</h3>
#       <pre>
# <%=  @log_data_change.notes %>
#       </pre>
#     }, :layout => 'content'
#   end

  #MM062017 - Enhance the 'log_data_changes' UI to view the 'notes' column as a structured HTML table and a grid view(optional) link that user can click
  def view_log_data_change
    @log_data_change = LogDataChange.find(params[:id])
    # if Globals.log_data_changes_types_to_ignore_for_tabular_display.include? @log_data_change.type_of_change.to_s
    if !@log_data_change.is_csv_log
      @table_definition = get_original_table_definition
    else
      @table_definition = get_table_definition
    end
    render :inline => %{
      <% @content_header_caption = "view log_data_change"%>

      <h2><%= @log_data_change.type_of_change %><h2>

      <%= @table_definition %>
    }, :layout => 'content'
  end

  def get_original_table_definition
    table_definition = "
      <table class='thinbordertable'>
        <tbody>
          <tr><th>Ref:</th><td> #{@log_data_change.ref_nos} <hd></tr>
          <tr><th>Created:</th><td> #{@log_data_change.created_at} <hd></tr>
          <tr><th>By:</th><td> #{@log_data_change.user_name} <hd></tr>
        </tbody>
      </table>
      <h3>Notes</h3>
      <pre>
        #{@log_data_change.notes}
      </pre>"
  end

  def get_table_definition
    @total_cols = 1
    @notes_headers = []
    @notes_keys = []
    @notes_details = []
    @notes_grid_details = []
    @notes_footers = []

    process_log_data_change_notes
    session[:notes_keys] = @notes_keys
    session[:notes_grid_details] = @notes_grid_details

    table_definition = "
      <table class='thinbordertable'>
       <tr class='hover-row'>
          <td style='font-weight:bold' colspan='#{@total_cols}' align='left'> #{@log_data_change.type_of_change} </td>
        </tr>
        <tr class='hover-row'>
          <td style='font-weight:bold' >Ref:</td>
          <td colspan='#{@total_cols - 1}' align='left'>#{@log_data_change.ref_nos} </td>
        </tr>
        <tr class='hover-row'>
          <td style='font-weight:bold' >Created:</td>
          <td colspan='#{@total_cols  - 1}' align='left'>#{@log_data_change.created_at} </td>
        </tr>
        <tr class='hover-row'>
          <td style='font-weight:bold' >By:</td>
          <td colspan='#{@total_cols  - 1}' align='left'>#{@log_data_change.user_name} </td>
        </tr>
        <tr class='hover-row'>
          <td colspan='#{@total_cols - 1 }' align='center' style='font-weight:bold' >Notes</td>
          <td align='center' style='font-weight:bold' >#{get_link}</td>
        </tr>
    "
    table_definition += " #{get_notes_definition}"
    table_definition += "</table> "
    return table_definition
  end

  def process_log_data_change_notes
    notes = @log_data_change.notes.split("\n")
    notes.each do |line|
      data = line.split(',')
      @total_cols = data.length if @total_cols < data.length
      if data.length > 1
        @notes_details << data
      else
        @notes_headers << data if @notes_details.empty?
        @notes_footers << data if !@notes_details.empty?
      end
    end
    @notes_keys = @notes_details[0]
    @notes_details.shift
    add_notes_details_to_data_hash(@notes_keys,@notes_details) if !@notes_details.empty?
  end

  def add_notes_details_to_data_hash(keys,notes_details)
    notes_details.each do |data_def|
      grid_data = Hash.new
      for i in 0..keys.length do
        grid_data.store(keys[i].to_s.strip,data_def[i])
      end
      @notes_grid_details << grid_data
    end
  end

  def get_notes_definition
    notes_definition = ""
    notes_definition += get_notes_headers_definition(@notes_headers) if !@notes_headers.empty?
    notes_definition += get_notes_keys_definition if !@notes_keys.empty?
    notes_definition += get_notes_details_definition if !@notes_details.empty?
    notes_definition += get_notes_headers_definition(@notes_footers)  if !@notes_footers.empty?
    return notes_definition
  end

  def get_notes_headers_definition(data)
    notes_headers = ""
    data.each do |line|
      notes_headers += "<tr class='hover-row'>
                            <td colspan='#{@total_cols}' style='font-weight:normal' bgcolor='whitesmoke'>#{line} </td>
                        </tr>"
    end
    return notes_headers
  end

  def get_notes_keys_definition
    notes_keys = ""
    td_col_span = @total_cols - @notes_keys.length
    notes_keys += "<tr class='hover-row'>"
    @notes_keys.each do |line|
      notes_keys += "<td style='font-weight:bold' bgcolor='whitesmoke'>#{line} </td>"
    end
    notes_keys += "<td colspan='#{td_col_span}' style='font-weight:bold' bgcolor='whitesmoke'> </td>" if td_col_span > 0
    notes_keys += "</tr>"
    return notes_keys
  end

  def get_notes_details_definition
    notes_details = ""
    td_col_span = @total_cols - @notes_keys.length
    @notes_grid_details.each do |line|
      notes_details += "<tr class='hover-row'>"
      @notes_keys.each do |key|
        field_name = key.to_s.strip
        notes_details += "<td style='font-weight:normal' bgcolor='whitesmoke'>#{line[field_name]} </td>"
      end
      notes_details += "<td colspan='#{td_col_span}' style='font-weight:bold' bgcolor='whitesmoke'> </td>" if td_col_span > 0
      notes_details += "</tr>"
    end
    return notes_details
  end

  def get_link
    link = ""
    if !@notes_details.empty?
      url =  request.host_with_port + "/" + request.path_parameters['controller'].to_s + "/show_in_grid_display/"
      link = "<a style=\"text-decoration:underline;cursor:pointer;padding-bottom:200px\" id=\"#{url}\" onclick=\"javascript:parent.call_open_window(this);\" >show_in_grid_display</a>"
    end
    return link
  end

  def show_in_grid_display
    render_show_in_grid_display
  end

  def render_show_in_grid_display
    @notes_grid_details = session[:notes_grid_details]
    @notes_keys = session[:notes_keys]
    render :inline => %{
      <% grid            = build_show_in_grid_display(@notes_grid_details,@notes_keys) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def update_log_data_change
    id = params[:log_data_change][:id]
    if id && @log_data_change = LogDataChange.find(id)
      if @log_data_change.update_attributes(params[:log_data_change])
        flash[:notice] = 'record saved'
        redirect_to_last_grid
      else
        render_edit_log_data_change
      end
    end
  rescue
    handle_error('record could not be saved')
  end

end
