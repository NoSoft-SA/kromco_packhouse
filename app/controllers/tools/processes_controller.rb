class Tools::ProcessesController < ApplicationController
  layout 'content'

  def program_name?
	"processes"
  end

  def bypass_generic_security?
    true
  end

  def list_processes
    return if authorise_for_web(program_name?,'read') == false
    render_list_processes
  end

  def render_list_processes
    @status_types = StatusType.find_by_sql("select * from status_types where parent_id is null")
    render :inline => %{
                      <% @content_header_caption = "'list of all processes'"%>
                      <% @tree_script = build_list_processes_tree(@status_types) %>
                      }, :layout => 'tree'
  end

  def new_process
    return if authorise_for_web(program_name?,'create')== false
    @action = "create_process"
    @caption = "create_process"
		render_process_form
  end

  def edit_process
    return if authorise_for_web(program_name?,'edit')== false
    @status_type = StatusType.find(params[:id])
    session[:process] = params[:id]
    @action = "update_process"
    @caption = "update_process"
    @is_edit = true
		render_process_form
  end

  def render_process_form
    render :inline => %{
		<% @tree_node_content_header = "create new process"%>
    <% @hide_content_pane = false %>
    <% @is_menu_loaded_view = true %>
		<%= build_process_form(@status_type,@action,@caption,@is_edit,@is_create_retry)%>
		}, :layout => 'tree_node_content'
  end

  def update_process
    @process = StatusType.find(session[:process])
    if(@process && @process.update_attributes(params[:status_type]))
      flash[:notice] = "process updated successfully"
      if(@process.friendly_name)
        @new_text = @process.friendly_name
      else
        @new_text = @process.status_type_code
      end
      render :inline => %{
                       <% @hide_content_pane = true %>
                           <% @is_menu_loaded_view = false %>
                           <% @tree_actions = render_edit_node_js(@new_text) %>
                       }, :layout => 'tree_node_content'

    end
  end

  def create_process
    begin
     @status_type = StatusType.new(params[:status_type])
     if @status_type.save
        @status_type_code = @status_type['status_type_code']
        session[:status_type_code] = @status_type_code

        flash[:notice] = "process created successfully"
        if(@status_type.friendly_name)
          @node_name     = @status_type.friendly_name
        else
          @node_name = @status_type.status_type_code
        end
        @node_type     = "process"
        @node_id       = @status_type.id.to_s
        @tree_name     = "processes"

        @statuses_parent_node = "process!#{@node_id}"
        @statuses_node_name     = "statuses"
        @statuses_node_type     = "statuses"
        @statuses_node_id       = @status_type.id.to_s
        @statuses_tree_name     = "processes"

        render :inline => %{
                        <% @hide_content_pane = true %>
                        <% @is_menu_loaded_view = false %>
                        <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) + " " + render_add_node_to_parent_js(@statuses_parent_node,@statuses_node_name,@statuses_node_type,@statuses_node_id,@tree_name) %>

                        }, :layout => 'tree_node_content'
     else
        @is_create_retry = true
        render_process_form
     end
    rescue
       handle_error('record could not be created')
    end
  end

  def new_sub_process
    return if authorise_for_web(program_name?,'create')== false
    render_new_sub_process
  end

  def render_new_sub_process
    session[:process] = params[:id]
    render :inline => %{
    <% @tree_node_content_header = "create new sub process"%>
    <% @hide_content_pane = false %>
    <% @is_menu_loaded_view = true %>
    <%= build_process_form(@status_type,'create_sub_process','create_sub_process',false,@is_create_retry)%>
    }, :layout => 'tree_node_content'
  end

  def create_sub_process
    begin
     @status_type = StatusType.new(params[:status_type])
     @status_type.parent_id = session[:process]
     if @status_type.save
        @status_type_code = @status_type['status_type_code']
        session[:status_type_code] = @status_type_code

        flash[:notice] = "sub process created successfully"
        if(@status_type.friendly_name)
          @node_name     = @status_type.friendly_name
        else
          @node_name = @status_type.status_type_code
        end

        @node_type     = "process"
        @node_id       = @status_type.id.to_s
        @tree_name     = "processes"

        @statuses_parent_node = "process!#{@status_type.id}"
        @statuses_node_name     = "statuses"
        @statuses_node_type     = "statuses"
        @statuses_node_id       = @status_type.id.to_s

        render :inline => %{
                        <% @hide_content_pane = true %>
                        <% @is_menu_loaded_view = false %>
                        <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) + " " + render_add_node_to_parent_js(@statuses_parent_node,@statuses_node_name,@statuses_node_type,@statuses_node_id,@tree_name)%>

                        }, :layout => 'tree_node_content'
     else
        params[:id] = session[:process]
        @is_create_retry = true
        render_new_sub_process
     end
    rescue
       handle_error('record could not be created')
    end
  end

  def delete_process
    begin
      process = StatusType.find(params[:id])
		  process.destroy
      flash[:notice] = "process deleted successfully"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>

                      <% @tree_actions = "window.parent.RemoveNode(null);" %>

                      }, :layout => 'tree_node_content'
    rescue
      flash[:error] = $!.to_s
      render :inline => %{
                        <% @hide_content_pane = true %>
                        <% @is_menu_loaded_view = true %>
                        }, :layout => 'tree_node_content'
    end
  end

  def delete_process_status
    begin
      status = Status.find(params[:id])
		  status.destroy
      flash[:notice] = "status deleted successfully"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>

                      <% @tree_actions = "window.parent.RemoveNode(null);" %>

                      }, :layout => 'tree_node_content'
    rescue
      flash[:error] = $!.to_s
      render :inline => %{
                        <% @hide_content_pane = true %>
                        <% @is_menu_loaded_view = true %>
                        }, :layout => 'tree_node_content'
    end
  end

  def edit_process_status
    return if authorise_for_web(program_name?,'edit')==false

     id = params[:id]
     if id && @status = Status.find(id)

      preceded_by = @status.preceded_by
      preceded_by_new_line = preceded_by.gsub(",","\n")
      @status.preceded_by =  preceded_by_new_line


       status_code = @status.status_code
       status_type_code = @status.status_type_code
       session[:status_type_code] = status_type_code
       transaction_status = TransactionStatus.find_by_sql("select * from transaction_statuses where transaction_statuses.status_code ='#{status_code}'
                                                    and transaction_statuses.status_type_code = '#{status_type_code}' ")

  #     if !transaction_status.empty?
  #    render :inline => %{
  #			  <script>
  #           alert('Cannot edit status record a status record exists in status histories ');
  #           window.close();
  #        </script>
  #        }
  #     else
       render_edit_status
  #     end
     end
  end

  def render_edit_status
    render :inline => %{
      <% @tree_node_content_header = "edit status"%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>
      <%= build_status_form(@status,'update_status','update_status',true)%>
      }, :layout => 'tree_node_content'
  end

 def update_status
    begin
     id = params[:status][:id]
     if id && @status = Status.find(id)
      preceded_by                   = params[:status][:preceded_by]
      # Save textarea of lines as a comma-separated string.
      # Convert returns to newlines, squash repeated newlines to a single newline, remove the last newline if present,
      # remove leading and trailing whitespace from each line and separate by commas.
      params[:status][:preceded_by] = preceded_by.gsub(/\r/, "\n").gsub(/\n+/, "\n").chomp.split("\n").map {|r| r.strip }.join(',')

       if @status.update_attributes(params[:status])
#        @statuses = eval(session[:query])
        render :inline => %{
          <script>
             alert('status successfully updated ');
             window.opener.location.reload(true);
             window.close();
        </script>
     }
     else
         render_edit_status
       end
     end
    rescue
     handle_error('record could not be saved')
    end
  end

  def new_status
    return if authorise_for_web(program_name?,'create')== false
      render_new_status
  end

  def render_new_status
    session[:process] = params[:id]
    status_type = StatusType.find(session[:process])
    session[:status_type_code] = status_type.status_type_code
    render :inline => %{
      <% @tree_node_content_header = "create new status"%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>
      <%= build_status_form(@status,'create_status','create_status',false,@is_create_retry)%>

      }, :layout => 'tree_node_content'
  end

   def create_status
   begin
    status_type_code              = session[:status_type_code]
    preceded_by                   = params[:status][:preceded_by]
    # Save textarea of lines as a comma-separated string.
    # Convert returns to newlines, squash repeated newlines to a single newline, remove the last newline if present,
    # remove leading and trailing whitespace from each line and separate by commas.
    params[:status][:preceded_by] = preceded_by.gsub(/\r/, "\n").gsub(/\n+/, "\n").chomp.split("\n").map {|r| r.strip }.join(',')

    @status = Status.new(params[:status])
    @status.status_type_code = status_type_code

    if @status.save
      flash[:notice] = "status created successfully"
      @node_name     = @status.status_code
      @node_type     = "status"
      @node_id       = @status.id.to_s
      @tree_name     = "processes"

      @alerts_parent_node = "status!#{@node_id}"
      @alerts_node_name     = "alerts"
      @alerts_node_type     = "alerts"
      #alert_num =  ProcessAlert.find_all_by_current_status_id(@status.id).length
      @alerts_node_id       = @status.id.to_s #+ "_#{alert_num}"

      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>
                      <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name)  + " " + render_add_node_to_parent_js(@alerts_parent_node,@alerts_node_name,@alerts_node_type,@alerts_node_id,@tree_name) %>

                      }, :layout => 'tree_node_content'
    else
      params[:id] = session[:process]
      @is_create_retry = true
      render_new_status
    end
   rescue
    handle_error('record could not be created')
   end
  end

def view_status_history
    process = StatusType.find(params[:id])
    dm_session[:status_type_code] = process.status_type_code
    dm_session['se_layout'] = 'tree_node_content'
    @tree_node_content_header = "view status history for process '#{process.friendly_name}'"
#    session['se_layout'] = 'content'
#    @tree_node_content_header = "<script>window.parent.frames[0].FRAMEBORDER = '0';</script>"
    dm_session["search_process_status_history_static_values"] = {'status_type_code'=>process.status_type_code}
    dm_session[:redirect] = true
    build_remote_search_engine_form("search_process_status_history.yml", "view_object_history")
    dm_session[:dm_instance] = false
  end

  def lookup_process_record

    settings = {:lookup=>true,
                      :lookup_search_file=>"/status_histories/#{dm_session[:status_type_code].to_s}_status_hist",#:default_values=>{'action_context'=>'general'},
                      :select_column_name=>'id',
                      :field_name=>'parameter_field_object_id'
                }

    @earl = ApplicationHelper::TextField.build_look_up_url_configs(self,settings)[:url]
    redirect_to(@earl)
  end

  def view_object_history
    if(session[:object_transaction_history_client_query_definition])
      @transaction_statuses = TransactionStatus.find_by_sql(session[:object_transaction_history_client_query_definition])
      session[:object_transaction_history_client_query_definition] = nil
    else
      @transaction_statuses = TransactionStatus.find_by_sql(dm_session[:search_engine_query_definition])
    end
    render_object_history_view_form
  end

  def render_object_history_view_form
    if(@transaction_statuses.length > 0)
      @transaction_status = @transaction_statuses[0]
      @content_header_caption = "'view process history of process:#{@transaction_status['status_type_code']} with id:#{@transaction_status['object_id']}'"
      render :inline => %{
        <script>
          var content_header = window.parent.parent.document.getElementById('content_header');
          content_header.innerHTML = "<%= @content_header_caption %>";
        </script>

        <table style="border-collapse: collapse;">
          <tr>
            <td>
              <%= link_to('view record', {:controller => request.path_parameters['controller'].to_s , :action => 'view_process_record', :id => @transaction_status['object_id'], :parent_id => @transaction_status['parent_id'],:ar_class_name=>@transaction_status['ar_class_name'],:status_type_code=>@transaction_status['status_type_code']},:popup=>['new_window', 'height=400,width=750,scrollbars=yes'],:style=>'text-decoration:underline;') %>
            </td>
          </tr>
          <tr>
            <td>
                  <% grid            = build_view_object_history_grid(@transaction_statuses) %>
                  <% grid.caption    = @content_header_caption %>
                  <% grid.fullpage=false %>
                  <% grid.width='1050' %>
                  <% @header_content = grid.build_grid_data %>

                  <%= grid.render_html %>
                  <%= grid.render_grid %>
            </td>
          </tr>
        </table>
        },:layout => 'content'
    else
      render :inline => %{
                           <script>
                             alert('no records found');
                           </script>
                         }, :layout => 'content'
    end
  end


  def view_process_record
#    process = StatusType.find_by_status_type_code(params[:status_type_code])
    @active_record_instance = eval("#{params[:ar_class_name]}.find(#{params[:id]})")
    @table_name = Inflector.tableize(params[:ar_class_name])
    @status_type_code = params[:status_type_code]
    render_process_record_view_form
  end

  def render_process_record_view_form
    @content_header_caption = "'view #{@status_type_code} record'"
    render :inline => %{
      <%= build_view_record_form(@active_record_instance, nil, "none", @table_name)%>
      }, :layout => 'content'
  end

  def view_transaction_status_parent
    @transaction_status = TransactionStatus.find_by_sql(" select transaction_statuses.created_on,transaction_statuses.parent_id,
transaction_statuses.status_code,transaction_statuses.status_type_code,transaction_statuses.username,transaction_statuses.object_id as the_object_id,status_types.ar_class_name
    from transaction_statuses
    join status_types on status_types.status_type_code = transaction_statuses.status_type_code
where transaction_statuses.id=#{params[:id]}")[0]
    render :inline => %{
      <%= build_parent_view_transaction_status_record_form(@transaction_status, nil, "none")%>
      }, :layout => 'content'
  end

  def view_transaction_status_object
    @table_name = Inflector.tableize(params[:id].split("|")[1])
    params[:id] = params[:id].split("|")[0]
    non_dm_detail
  end

  def view_transaction_status_child
    id = params[:id].split('|')[0]
    status_type_code = params[:id].split('|')[1]
    @child_transaction_statuses = ActiveRecord::Base.connection.select_all("select object_id,status_type_code from transaction_statuses where parent_id=#{id} and status_type_code='#{status_type_code}' group by object_id,status_type_code")
    @content_header_caption = "'list of child processes'"
      render :inline => %{
      <% grid            = build_transaction_statuses_grid(@child_transaction_statuses)%>
      <% grid.caption    = @content_header_caption %>
      <% @header_content = grid.build_grid_data %>
      <% grid.fullpage=false %>

      <% @pagination = pagination_links(@edi_intake_header_pages) if @edi_intake_header_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def view_transaction_status_process_record
    id = params[:id].split('|')[0]
    @status_type_code = params[:id].split('|')[1]
    @ar_class_name = TransactionStatus.find_by_sql("select status_types.ar_class_name from transaction_statuses join status_types on status_types.status_type_code = transaction_statuses.status_type_code where transaction_statuses.status_type_code='#{@status_type_code}'").map{|o| o.ar_class_name}[0]
    @table_name = Inflector.tableize(@ar_class_name)
    @active_record_instance = eval("#{@ar_class_name}.find(#{id})")
    render_process_record_view_form
  end

  def view_child_transaction_status_history
    id = params[:id].split('|')[0]
    status_type_code = params[:id].split('|')[1]
    @transaction_statuses = TransactionStatus.find_by_sql("select transaction_statuses.*,status_types.ar_class_name from transaction_statuses JOIN status_types on status_types.status_type_code = transaction_statuses.status_type_code WHERE(transaction_statuses.status_type_code='#{status_type_code}' and object_id=#{id}) ORDER BY transaction_statuses.created_on")
    render_object_history_view_form
  end

  def new_process_alert

    session[:status] = params[:id]
    return if authorise_for_web(program_name?,'create')== false
		render_new_process_alert_def
  end

  def render_new_process_alert_def
    render :inline => %{
		<% @tree_node_content_header = "create new process alert"%>
    <% @hide_content_pane = false %>
    <% @is_menu_loaded_view = true %>
		<%= build_process_alert_def_form(@process_alert_def,'create_process_alert_def','create_alert',false,@is_create_retry)%>
		}, :layout => 'tree_node_content'
  end

  def create_process_alert_def
    status = Status.find(session[:status])
    @process_alert_def = ProcessAlertDef.new
    @process_alert_def.status_id = session[:status]
    @process_alert_def.mode = params[:process_alert_def][:mode]
    @process_alert_def.description = params[:process_alert_def][:description]
    @process_alert_def.trigger_name = params[:process_alert_def][:trigger_name]
    @process_alert_def.process_alert_name = "#{status.status_type_code}_#{status.status_code}_#{params[:process_alert_def][:trigger_name]}_#{MesControlFile.next_seq_web(MesControlFile::PROCESS_ALERT)}"
    if(@process_alert_def.save)
      flash[:notice] = "process alert created successfully"
      @node_name     = @process_alert_def.process_alert_name
      @node_type     = "process_alert"
      @node_id       = @process_alert_def.id.to_s
      @tree_name     = "processes"

      render :inline => %{
                      <% @hide_content_pane = false %>
                      <% @is_menu_loaded_view = false %>
                      <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>
                      <script>
                        window.location.href = "/tools/processes/manage_process_alert_def/<%=@process_alert_def.id.to_s%>"
                      </script>
                      }, :layout => 'tree_node_content'
    else
      @is_create_retry = true
      render_new_process_alert_def
    end
  end

  def delete_process_alert_def
    @process_alert_def = ProcessAlertDef.find(params[:id])
    begin
      @process_alert_def.destroy
      flash[:notice] = "process alert deleted successfully"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                      <% @tree_actions = "window.parent.RemoveNode(null);" %>
                      }, :layout => 'tree_node_content'
    rescue
     flash[:error] = $!.to_s
      render :inline => %{
                        <% @hide_content_pane = true %>
                        <% @is_menu_loaded_view = true %>
                        }, :layout => 'tree_node_content'
    end
  end

  def manage_process_alert_def
    session[:process_alert_def] = params[:id]
    @process_alert_def = ProcessAlertDef.find(params[:id])
    @action = 'save_process_alert_def'
    render_process_alert_def_form
  end

  def render_process_alert_def_form
    render :inline => %{
    <% @hide_content_pane = false %>
    <% @is_menu_loaded_view = true %>
                      <% @tree_node_content_header = "manage process alert <bold>#{@process_alert_def.process_alert_name}"%>
                      <%= build_manage_process_alert_def_form(@process_alert_def,@action,'save') %>
                      }, :layout => 'tree_node_content'
  end

  def save_process_alert_def
    @process_alert_def = ProcessAlertDef.find(session[:process_alert_def])
    if(@process_alert_def.update_attributes(params[:process_alert_def]))
      flash[:notice] = "record updated successfully"
      render_process_alert_def_form
    else
      flash[:error] = "could not updat record"
      params[:id] = session[:process_alert_def]
      manage_process_alert_def
    end
  end

  def search_pallet_status_histories
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true

    dm_session['se_layout'] = 'content'
    @content_header_caption = "'find pallet system status histories'"
    dm_session[:redirect] = true
    build_remote_search_engine_form("search_pallet_system_status_histories.yml", "view_object_history")
    dm_session[:dm_instance] = false
  end

  def show_object_transactions_from_parent
    model, id = params[:model].split(/\//)
    tran = TransactionStatus.find(id)
    redirect_to :action => 'show_object_transactions', :model => "#{model}/#{tran['object_id']}"
  end

  def show_object_transactions
    model, id = params[:model].split(/\//)
    if 'PalletSeq' == model # ps to get Pallet
      pseq = PalletSequence.find(:first, :select => 'pallet_id', :conditions => ['id = ?', id])
      model = 'Pallet'
      id    = pseq.pallet_id
    end
    klass = model.constantize

    begin
      @model = klass.find(id)
    rescue
      @model = nil # Model may have been deleted...
    end

    @rows = TransactionStatus.model_rows(klass, id)
  end

  def show_child_transactions
    id = params[:id]
    @rows = TransactionStatus.child_rows(id)
    raise MesScada::InfoError, 'This process currently only handles Pallets as child transactions' if @rows.any? {|r| 'Pallet' != r.this_class_name }
  end

  def view_transaction_status_object_from_parent
    id, model = params[:id].split('|')
    tran = TransactionStatus.find(id)
    redirect_to :action => 'view_transaction_status_object', :id => "#{tran['object_id']}|#{model}"
  end

end
